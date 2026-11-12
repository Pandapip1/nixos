{
  config,
  lib,
  pkgs,
  ...
}:

let
  captivePortalConfig = "/var/run/named/captive-portal.conf";
  dnsCfg = config.localDns;
  fw = dnsCfg.firewall;
  overTor = dnsCfg.recurseOverTor;
  pfAnchor = "com.apple/dns-over-tor";
  directDnsFile = "/var/run/named/direct-dns";
  # BIND and Tor need users of their own: the firewall picks out BIND's
  # traffic by user, and Tor's own connections must not match.
  namedUser = "_named";
  torUser = "_tor";
  torRunUser = if overTor then "root" else torUser;
  torRunGroup = if overTor then "wheel" else torUser;
  bindConfig = config.localDns.bindConfig {
    directory = "/var/run/named";
    logDestination = "stderr";
  };
  # BIND's port-53 traffic (only BIND's, picked out by user) either goes to
  # private networks and the captive-portal DNS servers directly, or is
  # routed to loopback and redirected into Tor's transparent proxy; anything
  # else, UDP to public servers included, is dropped. Loaded into an anchor
  # under com.apple/, which macOS's own /etc/pf.conf already evaluates.
  pfRules = pkgs.writeText "dns-over-tor.pf" ''
    table <dns_private> const { ${lib.concatStringsSep ", " (fw.privateRanges4 ++ fw.privateRanges6)} }
    table <direct_dns> persist

    rdr pass on lo0 inet proto tcp from any to ! <dns_private> port 53 -> 127.0.0.1 port ${toString fw.torTransPort}

    pass out quick proto { tcp, udp } from any to <dns_private> port 53 user ${namedUser}
    pass out quick proto { tcp, udp } from any to <direct_dns> port 53 user ${namedUser}
    pass out quick on ! lo0 route-to (lo0 127.0.0.1) inet proto tcp from any to any port 53 user ${namedUser}
    block drop out quick on ! lo0 proto { tcp, udp } from any to any port 53 user ${namedUser}
  '';
  pfLoad = pkgs.writeShellScript "dns-over-tor-pf" ''
    # pf is reference-counted on macOS; take a reference so it stays enabled.
    /sbin/pfctl -E 2>/dev/null
    /sbin/pfctl -q -a ${pfAnchor} -f ${pfRules}
    # Reloading the anchor empties <direct_dns>; restore it from the watcher.
    if [ -s ${directDnsFile} ]; then
      /sbin/pfctl -q -a ${pfAnchor} -t direct_dns -T replace -f ${directDnsFile}
    fi
  '';
  torConfig = pkgs.writeText "torrc" ''
    DataDirectory /var/db/tor
    # No "User": on macOS the pf NAT lookup (DIOCNATLOOK) that TransPort relies
    # on is checked for root on every ioctl, not only when /dev/pf is opened,
    # so Tor must keep running as root for the transparent proxy to work.
    ${lib.optionalString (!overTor) "User ${torUser}"}
    DNSPort 127.0.0.1:9053
    SocksPort 127.0.0.1:9050
    ${lib.optionalString overTor "TransPort 127.0.0.1:${toString fw.torTransPort}"}
  '';
  torStart = pkgs.writeShellScript "tor-start" ''
    # Tor insists its data directory belongs to the user it runs as: root when
    # it is the transparent proxy (see torConfig), _tor otherwise.
    install -d -m 700 -o ${torRunUser} -g ${torRunGroup} /var/db/tor
    chown -R ${torRunUser}:${torRunGroup} /var/db/tor
    # tor-pf: Tor built with pf support, which TransPort needs on macOS.
    exec ${lib.getExe pkgs.tor-pf} -f ${torConfig}
  '';
  # BIND owns caching, but mDNSResponder sits in front of it and caches
  # answers too, failures included. Flush it whenever BIND (re)starts and
  # whenever the network changes, so nothing BIND failed in the meantime
  # stays stuck there after BIND recovers.
  flushSystemCache = ''
    flush_system_cache() {
      /usr/bin/dscacheutil -flushcache
      /usr/bin/killall -HUP mDNSResponder 2>/dev/null || true
    }
  '';
  bindStart = pkgs.writeShellApplication {
    name = "bind-start";
    runtimeInputs = with pkgs; [
      bind
      coreutils
    ];
    text = ''
      set -euo pipefail
      ${flushSystemCache}

      install -d -m 755 -o ${namedUser} -g ${namedUser} /var/run/named /var/run/named/slaves
      chown -R ${namedUser}:${namedUser} /var/run/named
      install -m 644 -o ${namedUser} -g ${namedUser} /dev/null ${captivePortalConfig}
      # -f keeps named in the foreground but, unlike -g, honours the logging
      # statement. It logs "running" once it is answering queries; flush then.
      ${pkgs.bind-resolver}/bin/named -f -u ${namedUser} ${lib.escapeShellArgs dnsCfg.namedArgs} -c ${bindConfig} 2>&1 |
        while IFS= read -r line; do
          printf '%s\n' "$line"
          case "$line" in
            *" running") flush_system_cache ;;
          esac
        done
    '';
  };
  bindCaptivePortalWatcher = pkgs.writeShellApplication {
    name = "bind-captive-portal-watcher";
    runtimeInputs = with pkgs; [ coreutils gawk ];
    text = ''
      set -u
      ${flushSystemCache}

      # Point every network service's DNS at BIND. nix-darwin's networking.dns
      # only covers the services listed in knownNetworkServices; any other
      # (a new adapter, tethering) would use its network's DNS and bypass BIND
      # and Tor. Disabled services are listed with a leading "*".
      pin_dns() {
        /usr/sbin/networksetup -listallnetworkservices | tail -n +2 |
          while IFS= read -r service; do
            service=''${service#\*}
            current=$(/usr/sbin/networksetup -getdnsservers "$service" | tr '\n' ' ')
            if [ "$current" != "127.0.0.1 ::1 " ]; then
              /usr/sbin/networksetup -setdnsservers "$service" 127.0.0.1 ::1
            fi
          done
      }

      update() {
        interface=$(/sbin/route -n get default 2>/dev/null |
        pin_dns
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

        install -d -m 755 -o ${namedUser} -g ${namedUser} /var/run/named
        temporary=$(mktemp /var/run/named/captive-portal.conf.XXXXXX)
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
        chown ${namedUser}:${namedUser} "$temporary"

        ${lib.optionalString overTor ''
          # Let BIND reach exactly these servers past the firewall; see pfRules.
          printf '%s\n' "$filtered" > ${directDnsFile}
          /sbin/pfctl -q -a ${pfAnchor} -t direct_dns -T replace -f ${directDnsFile} 2>/dev/null || true
        ''}
        if ! cmp -s "$temporary" ${captivePortalConfig}; then
          mv -f "$temporary" ${captivePortalConfig}
          if [ -s /var/run/named/named.pid ]; then
            kill -HUP "$(cat /var/run/named/named.pid)" 2>/dev/null || true
          fi
        else
          rm -f "$temporary"
        fi
        flush_system_cache
      }

      update
      # React to the routing socket instead of polling: address changes,
      # interface state, and routes through a gateway (the default route).
      # Plain host routes (ARP entries), lookups and misses are ignored.
      # A burst of messages is coalesced into one update.
      /sbin/route -n monitor | while IFS= read -r line; do
        case "$line" in
          RTM_NEWADDR:*|RTM_DELADDR:*|RTM_IFINFO:*) ;;
          RTM_ADD:*GATEWAY*|RTM_DELETE:*GATEWAY*|RTM_CHANGE:*GATEWAY*) ;;
          *) continue ;;
        esac
        while IFS= read -r -t 1 _; do :; done
        update
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

  users = {
    knownUsers = [
      namedUser
      torUser
    ];
    knownGroups = [
      namedUser
      torUser
    ];
    users.${namedUser} = {
      uid = 440;
      gid = 440;
      description = "BIND";
      home = "/var/empty";
      shell = "/usr/bin/false";
      isHidden = true;
    };
    users.${torUser} = {
      uid = 470;
      gid = 470;
      description = "Tor";
      home = "/var/empty";
      shell = "/usr/bin/false";
      isHidden = true;
    };
    groups.${namedUser}.gid = 440;
    groups.${torUser}.gid = 470;
  };

  # Keep five 1 MiB rotations of the BIND and Tor logs (newsyslog: count size when flags).
  environment.etc."newsyslog.d/named.conf".text = ''
    /var/log/named.log  644  5  1024  *  J
    /var/log/tor.log    644  5  1024  *  J
  '';

  launchd.daemons = {
    tor.serviceConfig = {
      ProgramArguments = [ "${torStart}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      StandardOutPath = "/var/log/tor.log";
      StandardErrorPath = "/var/log/tor.log";
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
      StandardOutPath = "/var/log/named.log";
      StandardErrorPath = "/var/log/named.log";
    };
    dns-over-tor-pf = lib.mkIf overTor {
      serviceConfig = {
        ProgramArguments = [ "${pfLoad}" ];
        RunAtLoad = true;
      };
    };
    bind-captive-portal.serviceConfig = {
      ProgramArguments = [ "${lib.getExe bindCaptivePortalWatcher}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
    };
  };
}
