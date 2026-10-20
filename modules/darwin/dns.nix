{
  config,
  lib,
  pkgs,
  ...
}:

let
  captivePortalConfig = "/var/run/named/captive-portal.conf";
  bindConfig = config.localDns.bindConfig { directory = "/var/run/named"; };
  torConfig = pkgs.writeText "torrc" ''
    DataDirectory /var/db/tor
    User nobody
    DNSPort 127.0.0.1:9053
    SocksPort 127.0.0.1:9050
  '';
  torStart = pkgs.writeShellScript "tor-start" ''
    install -d -m 700 -o nobody -g nobody /var/db/tor
    exec ${lib.getExe pkgs.tor} -f ${torConfig}
  '';
  bindStart = pkgs.writeShellApplication {
    name = "bind-start";
    runtimeInputs = with pkgs; [
      bind
      coreutils
    ];
    text = ''
      set -euo pipefail

      install -d -m 755 -o nobody -g nobody /var/run/named /var/run/named/slaves
      install -m 644 -o nobody -g nobody /dev/null ${captivePortalConfig}
      exec ${pkgs.bind}/bin/named -g -u nobody -c ${bindConfig}
    '';
  };
  bindCaptivePortalWatcher = pkgs.writeShellApplication {
    name = "bind-captive-portal-watcher";
    runtimeInputs = with pkgs; [ coreutils gawk ];
    text = ''
      set -u

      while true; do
        interface=$(/sbin/route -n get default 2>/dev/null |
          awk '$1 == "interface:" { print $2; exit }')
        servers=""
        if [ -n "$interface" ]; then
          servers=$(/usr/sbin/ipconfig getpacket "$interface" 2>/dev/null |
            awk -F '[{}]' '/domain_name_server/ {
              gsub(/,/, " ", $2)
              for (i = 1; i <= NF; i++) print $i
            }')
        fi
        if [ -z "$servers" ]; then
          servers=$(/sbin/route -n get default 2>/dev/null |
            awk '$1 == "gateway:" { print $2; exit }')
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

        install -d -m 755 -o nobody -g nobody /var/run/named
        temporary=$(mktemp /var/run/named/captive-portal.conf.XXXXXX)
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
        chown nobody:nobody "$temporary"

        if ! cmp -s "$temporary" ${captivePortalConfig}; then
          mv -f "$temporary" ${captivePortalConfig}
          if [ -s /var/run/named/named.pid ]; then
            kill -HUP "$(cat /var/run/named/named.pid)" 2>/dev/null || true
          fi
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
  networking.dns = [
    "127.0.0.1"
    "::1"
  ];

  environment.systemPackages = with pkgs; [
    bind
    tor
  ];

  launchd.daemons = {
    tor.serviceConfig = {
      ProgramArguments = [ "${torStart}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
    };
    bind.serviceConfig = {
      # launchd can load this plist before the Nix store volume is available.
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path /nix/store && exec ${lib.getExe bindStart}"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
    };
    bind-captive-portal.serviceConfig = {
      ProgramArguments = [ "${lib.getExe bindCaptivePortalWatcher}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
    };
  };
}
