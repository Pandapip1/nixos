{
  config,
  lib,
  pkgs,
  ...
}:

let
  captivePortalConfig = "/run/named/captive-portal.conf";
  dnsCfg = config.localDns;
  fw = dnsCfg.firewall;
  overTor = dnsCfg.recurseOverTor;
  nftTable = "dns-over-tor";
  bindCaptivePortalWatcher = pkgs.writeShellApplication {
    name = "bind-captive-portal-watcher";
    runtimeInputs = with pkgs; [ bind coreutils gawk iproute2 networkmanager nftables ];
    text = ''
      set -u

      update() {
        servers=$(nmcli -g IP4.DNS,IP6.DNS device show 2>/dev/null || true)
        if [ -z "$servers" ]; then
          servers=$(ip route show default 2>/dev/null |
            awk '/^default/ { print $3; exit }')
        fi

        filtered=""
        for server in $servers; do
          case "$server" in
            127.0.0.1|::1|*[^0-9A-Fa-f:.]*) ;;
            *) filtered="$filtered
$server" ;;
          esac
        done
        filtered=$(printf '%s\n' "$filtered" | awk 'NF && !seen[$0]++')

        temporary=$(mktemp /run/named/captive-portal.conf.XXXXXX)
        trap 'rm -f "$temporary"' EXIT
        : > "$temporary"
        if [ -n "$filtered" ]; then
          for zone in ${lib.escapeShellArgs config.localDns.captivePortalZones}; do
            printf 'zone "%s" {\n  type forward;\n  forward only;\n  forwarders {\n' "$zone" >> "$temporary"
            for server in $filtered; do
              printf '    %s;\n' "$server" >> "$temporary"
            done
            printf '  };\n};\n' >> "$temporary"
          done
          # These servers are reached directly, not through Tor: plain UDP/TCP
          # and IPv6 allowed (security/dns.nix sets the opposite for every
          # other public server).
          for server in $filtered; do
            printf 'server %s { tcp-only no; bogus no; };\n' "$server" >> "$temporary"
          done
        fi
        chmod 644 "$temporary"
        chown named:named "$temporary"

        ${lib.optionalString overTor ''
          # Let BIND reach exactly these servers past the firewall.
          {
            echo "flush set inet ${nftTable} direct4"
            echo "flush set inet ${nftTable} direct6"
            for server in $filtered; do
              case "$server" in
                *:*) echo "add element inet ${nftTable} direct6 { $server }" ;;
                *) echo "add element inet ${nftTable} direct4 { $server }" ;;
              esac
            done
          } | nft -f - || true
        ''}
        if ! cmp -s "$temporary" ${captivePortalConfig}; then
          mv -f "$temporary" ${captivePortalConfig}
          rndc -k /etc/bind/rndc.key reconfig || true
        else
          rm -f "$temporary"
        fi
        trap - EXIT
      }

      update
      # React to address, route and NetworkManager changes instead of
      # polling. A burst of events is coalesced into one update.
      { ip monitor address route & nmcli monitor & wait; } |
        while IFS= read -r _; do
          while IFS= read -r -t 1 _; do :; done
          update
        done
    '';
  };
in
{
  networking.nameservers = [
    "127.0.0.1"
    "::1"
  ];

  services = {
    bind = {
      enable = true;
      package = pkgs.bind-resolver;
      extraArgs = dnsCfg.namedArgs;
      configFile = config.localDns.bindConfig {
        directory = "/run/named";
        rndcKeyFile = "/etc/bind/rndc.key";
      };
    };
    # TODO: Create & upstream option to configure port
    avahi = {
      enable = true;
      settings.publish = {
        disable-publishing = false;
        disable-user-service-publishing = false;
        publish-addresses = true;
        publish-domain = true;
        publish-hinfo = true;
        publish-workstation = true;
      };
      # Take over mDNS resolving responsibilities
      nssmdns4 = true;
      nssmdns6 = true;
    };
  };
  services.tor = {
    enable = true;
    client = {
      enable = true;
      dns.enable = true;
      transparentProxy.enable = overTor;
    };
  };

  # BIND's port-53 traffic (only BIND's, picked out by user) goes to private
  # networks and the captive-portal DNS servers directly; TCP to anything else
  # is redirected into Tor's transparent proxy, and the rest (UDP, IPv6) is
  # dropped, so recursion fails rather than leaving outside Tor.
  networking.nftables.tables.${nftTable} = lib.mkIf overTor {
    family = "inet";
    content = ''
      set private4 {
        type ipv4_addr
        flags interval
        elements = { ${lib.concatStringsSep ", " fw.privateRanges4} }
      }
      set private6 {
        type ipv6_addr
        flags interval
        elements = { ${lib.concatStringsSep ", " fw.privateRanges6} }
      }
      # Filled in by bind-captive-portal from the network's DHCP DNS servers.
      set direct4 { type ipv4_addr; }
      set direct6 { type ipv6_addr; }

      chain nat-output {
        type nat hook output priority dstnat; policy accept;
        meta skuid "named" tcp dport 53 ip daddr != @private4 ip daddr != @direct4 redirect to :${toString fw.torTransPort}
      }

      chain filter-output {
        type filter hook output priority filter; policy accept;
        meta skuid "named" udp dport 53 ip daddr != @private4 ip daddr != @direct4 drop
        meta skuid "named" meta l4proto { tcp, udp } th dport 53 ip6 daddr != @private6 ip6 daddr != @direct6 drop
      }
    '';
  };
  # The build-time ruleset check runs where the named user doesn't exist.
  networking.nftables.preCheckRuleset = lib.mkIf overTor ''
    sed -i 's/skuid "named"/skuid root/g' ruleset.conf
  '';

  systemd.tmpfiles.rules = [
    "d /run/named 0755 named named -"
    "f ${captivePortalConfig} 0644 named named -"
  ];

  systemd.services.bind-captive-portal = {
    description = "Update BIND forwarding for captive portal probes";
    after = [ "NetworkManager.service" "bind.service" ];
    wants = [ "NetworkManager.service" "bind.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = lib.getExe bindCaptivePortalWatcher;
      Restart = "always";
      RestartSec = 10;
    };
  };
}
