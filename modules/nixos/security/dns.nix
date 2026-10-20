{
  config,
  lib,
  pkgs,
  ...
}:

let
  captivePortalConfig = "/run/named/captive-portal.conf";
  bindCaptivePortalWatcher = pkgs.writeShellApplication {
    name = "bind-captive-portal-watcher";
    runtimeInputs = with pkgs; [ bind coreutils gawk iproute2 networkmanager ];
    text = ''
      set -u

      while true; do
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
        fi
        chmod 644 "$temporary"
        chown named:named "$temporary"

        if ! cmp -s "$temporary" ${captivePortalConfig}; then
          mv -f "$temporary" ${captivePortalConfig}
          rndc -k /etc/bind/rndc.key reconfig || true
        else
          rm -f "$temporary"
        fi
        trap - EXIT
        sleep 10
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
      package = pkgs.bind;
      configFile = config.localDns.bindConfig {
        directory = "/run/named";
        rndcKeyFile = "/etc/bind/rndc.key";
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
  services.tor = {
    enable = true;
    client = {
      enable = true;
      dns.enable = true;
    };
  };

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
