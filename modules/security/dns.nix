{
  pkgs,
  ...
}:

{
  services = {
    unbound = {
      enable = true;
      resolveLocalQueries = false;
      package = pkgs.unbound-full;
      settings = {
        server = {
          interface = [ "::" ];
          port = 53;
          verbosity = 1;
          root-hints = "/run/dns/root.hints";

          # disable DNSSEC validation, needed for opennic
          # TODO(@Pandapip1): OpenNIC does support DNSSEC
          # https://wiki.opennic.org/opennic/dnssec
          val-permissive-mode = "yes";
        };
      };
    };
    # TODO: Create & upstream option to configure port
    avahi = {
      enable = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
      # Take over mDNS resolving responsibilities
      nssmdns4 = true;
      nssmdns6 = true;
    };
  };
  networking.nameservers = [
    "::1"
  ];

  systemd.services.opennic-root-hints = {
    description = "Fetch OpenNIC root hints with env-based server failover";
    wantedBy = [ "multi-user.target" ];

    before = [ "dns-root-merge.service" ];

    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      RuntimeDirectory = "opennic";

      # Environment-provided server list (space-separated)
      Environment = ''
        OPENNIC_SERVERS="2001:470:4212:10:0:100:53:10 161.97.219.84 168.119.153.26"
      '';
    };

    path = with pkgs; [
      dnsutils
      coreutils
      gawk
    ];

    script = ''
      set -euo pipefail

      OUT="$RUNTIME_DIRECTORY/root.hints"
      TMP=$(mktemp)

      # Convert env var → bash array
      IFS=' ' read -r -a SERVERS <<< "$OPENNIC_SERVERS"

      success=0

      for srv in "''${SERVERS[@]}"; do
        echo "Trying $srv" >&2

        if dig . NS @"$srv" \
            +time=2 +tries=1 \
            +noall +answer +additional > "$TMP"; then
          echo "Success via $srv" >&2
          success=1
          break
        fi
      done

      if [ "$success" -ne 1 ]; then
        echo "All OpenNIC servers failed" >&2
        exit 1
      fi

      awk '
        $4 == "NS" { print ".\t3600\tIN\tNS\t" $5 }
        $4 == "A" || $4 == "AAAA" {
          print $1 "\t3600\tIN\t" $4 "\t" $5
        }
      ' "$TMP" > "$OUT"

      rm -f "$TMP"

      while true; do
        sleep 9999999
      done
    '';
  };
  systemd.services.dns-root-merge = {
    description = "Merge ICANN and OpenNIC root hints";
    wantedBy = [
      "multi-user.target"
      "unbound.service"
    ];

    # ensure OpenNIC data exists first
    after = [ "opennic-root-hints.service" ];
    requires = [ "opennic-root-hints.service" ];

    before = [ "unbound.service" ];

    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      RuntimeDirectory = "dns";
    };

    path = with pkgs; [
      coreutils
      gawk
    ];

    script = ''
      set -euo pipefail

      OUT="$RUNTIME_DIRECTORY/root.hints"

      OPENNIC_HINTS="/run/opennic/root.hints"

      TIMEOUT=5
      i=0
      while [ ! -f "$OPENNIC_HINTS" ]; do
        if [ "$i" -ge "$TIMEOUT" ]; then
          echo "Missing OpenNIC root hints" >&2
          exit 1
        fi
        sleep 1
        i=$((i+1))
      done

      cat \
        ${pkgs.dns-root-data}/root.hints \
        "$OPENNIC_HINTS" \
        > "$OUT"

      # optional sanity normalization (deduplicate identical lines)
      awk '!seen[$0]++' "$OUT" > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"

      while true; do
        sleep 9999999
      done
    '';
  };
}
