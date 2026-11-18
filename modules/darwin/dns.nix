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
  # BIND writes and rotates its own logs (a log file channel with versions and
  # size): launchd opens a job's StandardOutPath once, so newsyslog renaming
  # that file left launchd writing to the renamed (then deleted) file and the
  # logs were lost. Tor reopens its log on SIGHUP, which newsyslog sends.
  namedLogDir = "/var/log/named";
  torLogDir = "/var/log/tor";
  torPidFile = "/var/db/tor/tor.pid";
  # Created at start (rndc-confgen); /etc/bind/rndc.key is where rndc looks.
  rndcKeyFile = "/etc/bind/rndc.key";
  # launchd loads daemons at boot before the Nix store volume is mounted; a
  # job whose program isn't there yet fails (EX_CONFIG) and isn't retried.
  # After the macOS 27 reboot tor, the pf anchor job and the captive-portal
  # watcher all stayed down that way (only BIND, which waited, came up), so
  # every lookup failed. Every job here waits for the store first.
  afterStore = program: [
    "/bin/sh"
    "-c"
    "/bin/wait4path /nix/store && exec ${program}"
  ];
  # BIND and Tor need users of their own: the firewall picks out BIND's
  # traffic by user, and Tor's own connections must not match.
  namedUser = "_named";
  torUser = "_tor";
  torRunUser = if overTor then "root" else torUser;
  torRunGroup = if overTor then "wheel" else torUser;
  bindConfig = config.localDns.bindConfig {
    directory = "/var/run/named";
    inherit rndcKeyFile;
    logDestination = ''file "${namedLogDir}/named.log" versions 5 size 2m'';
    errorLogDestination = ''file "${namedLogDir}/query-errors.log" versions 3 size 1m'';
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

    # Tor's DNSPort resolves any name at an exit; it is there only for BIND's
    # "onion" zone. Nobody else may use it.
    pass out quick on lo0 proto udp from any to 127.0.0.1 port ${toString fw.torDnsPort} user ${namedUser}
    block drop out quick on lo0 proto { tcp, udp } from any to any port ${toString fw.torDnsPort}
  '';
  # (Re)load the anchor. Run at boot, on every activation, before named starts
  # and on every network change: the anchor is what routes BIND's queries
  # into Tor, and without it they fail ("host unreachable") or leak.
  pfLoad = pkgs.writeShellScript "dns-over-tor-pf" ''
    # pf is reference-counted on macOS (pfctl -E takes a reference); take one
    # only when pf is off, so reloading doesn't pile up references.
    if ! /sbin/pfctl -s info 2>/dev/null | grep -q "^Status: Enabled"; then
      /sbin/pfctl -E 2>/dev/null
    fi
    # The redirect into Tor happens on lo0 (route-to lo0, then rdr on lo0, and
    # the replies are translated back on lo0), so pf must not skip loopback.
    # Internet Sharing (e.g. a VM's NAT: Virtualization.framework, vmnet)
    # loads a main ruleset with "set skip on lo0"; then every BIND query fails
    # with "host unreachable". Skipping is a main-ruleset option an anchor
    # cannot override, so clear it with an options-only load (-O), which
    # keeps the main ruleset and Internet Sharing's NAT rules as they are.
    if /sbin/pfctl -s Interfaces -v 2>/dev/null | grep -q '^lo0 (skip)'; then
      echo "dns-over-tor: pf was skipping lo0 (Internet Sharing?); clearing it" >&2
      /sbin/pfctl -q -O -f /dev/null
    fi
    /sbin/pfctl -q -a ${pfAnchor} -f ${pfRules}
    # Reloading the anchor empties <direct_dns>; restore it from the watcher.
    if [ -s ${directDnsFile} ]; then
      /sbin/pfctl -q -a ${pfAnchor} -t direct_dns -T replace -f ${directDnsFile}
    fi
  '';
  torConfig = pkgs.writeText "torrc" ''
    DataDirectory /var/db/tor
    PidFile ${torPidFile}
    Log notice file ${torLogDir}/tor.log
    # No "User": on macOS the pf NAT lookup (DIOCNATLOOK) that TransPort relies
    # on is checked for root on every ioctl, not only when /dev/pf is opened,
    # so Tor must keep running as root for the transparent proxy to work.
    ${lib.optionalString (!overTor) "User ${torUser}"}
    # Only for .onion (BIND's "onion" zone forwards here): Tor resolves onion
    # names itself. Nothing else may be resolved through Tor's exits.
    DNSPort 127.0.0.1:${toString fw.torDnsPort}
    SocksPort 127.0.0.1:9050
    ${lib.optionalString overTor ''
      # BIND's connections to DNS servers arrive here. No isolation flags:
      # streams share Tor's open circuits. A full lookup reaches dozens of
      # server addresses, and isolating them (IsolateDestAddr) made each
      # one wait for a circuit of its own: measured 2026-11-17 through the
      # SocksPort, a server's first answer took 1.9 s median and 5.3 s p90
      # (none within 1 s) on its own circuit, against 0.7 s and 1.05 s on
      # shared circuits, and with ~150 servers in use the circuits queued
      # behind MaxClientCircuitsPending ("Tried for 120 seconds ... waiting
      # for circuit"). BIND resolved 3 of 200 uncached names.
      TransPort 127.0.0.1:${toString fw.torTransPort}
      # A stalled exit is handled per stream instead: give up on an exit
      # that hasn't connected after 10 s (Tor's minimum; its default goes
      # to 15 s after the first try), retry the stream on a new circuit and
      # stop giving the stalled circuit new streams.
      CircuitStreamTimeout 10
    ''}
  '';
  torStart = pkgs.writeShellScript "tor-start" ''
    # Tor insists its data directory belongs to the user it runs as: root when
    # it is the transparent proxy (see torConfig), _tor otherwise.
    install -d -m 700 -o ${torRunUser} -g ${torRunGroup} /var/db/tor
    chown -R ${torRunUser}:${torRunGroup} /var/db/tor
    install -d -m 755 -o ${torRunUser} -g ${torRunGroup} ${torLogDir}
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
${lib.optionalString overTor ''

      # The firewall anchor that routes BIND's queries into Tor.
      ${pfLoad}
    ''}
      # named writes and rotates its logs itself, as ${namedUser} once it has
      # dropped root, so the directory and files must be its own.
      install -d -m 755 -o ${namedUser} -g ${namedUser} ${namedLogDir}
      for log in named.log query-errors.log; do
        touch ${namedLogDir}/$log
        chown ${namedUser}:${namedUser} ${namedLogDir}/$log
      done

      # Key for rndc (root only) and for named's control channel; named
      # rereads it as ${namedUser} on reconfig. "sudo rndc status" then works.
      install -d -m 755 /etc/bind
      if [ ! -s ${rndcKeyFile} ]; then
        rndc-confgen -a -A hmac-sha256 -k rndc-key -c ${rndcKeyFile}
      fi
      chown root:${namedUser} ${rndcKeyFile}
      chmod 640 ${rndcKeyFile}

      # named logs "running" once it is answering queries; flush then.
      #
      # It also logs every query it answers with SERVFAIL (query-errors).
      # mDNSResponder caches a SERVFAIL as "no such record" (and lengthens
      # that on repeats), so a lookup that failed once keeps failing for apps
      # long after BIND can answer it. Flush shortly after a failure, once
      # mDNSResponder has had a chance to cache it; at most every 5 s.
      #
      # Follow the log files by name (-F), across named's own rotations.
      # launchd ends this watcher with the job (same process group).
      tail -n 0 -F ${namedLogDir}/named.log ${namedLogDir}/query-errors.log |
        {
          last_flush=-5
          while IFS= read -r line; do
            case "$line" in
              *" running") flush_system_cache ;;
              *"query-errors: "*"query failed"*)
                if [ $((SECONDS - last_flush)) -ge 5 ]; then
                  last_flush=$SECONDS
                  (sleep 1; flush_system_cache) &
                fi
                ;;
            esac
          done
        } &

      # -f keeps named in the foreground but, unlike -g, honours the logging
      # statement. Its stderr (launchd's log) only gets what it prints before
      # reading the configuration, and crashes.
      exec ${pkgs.bind-resolver}/bin/named -f -u ${namedUser} ${lib.escapeShellArgs dnsCfg.namedArgs} -c ${bindConfig}
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
        pin_dns
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
          # Reload the whole anchor, not just the table: it must be in place
          # on every network, however it was lost.
          printf '%s\n' "$filtered" > ${directDnsFile}
          ${pfLoad}
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
        # stdin here is the monitor stream; keep update's commands off it.
        update < /dev/null
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

  # Keep five 1 MiB rotations of Tor's log (newsyslog: mode count size when
  # flags pid-file signal). After renaming it, newsyslog sends Tor SIGHUP (1),
  # on which Tor reopens its log file (and rereads torrc). named rotates its
  # own logs (see bindConfig), so it has no entry here.
  environment.etc."newsyslog.d/named.conf".text = ''
    ${torLogDir}/tor.log  644  5  1024  *  J  ${torPidFile}  1
  '';

  # Reload the firewall anchor on every activation too: a switch that leaves
  # the launchd jobs unchanged reruns none of them.
  system.activationScripts.postActivation.text = lib.mkIf overTor (
    lib.mkAfter ''
      echo "reloading the dns-over-tor firewall anchor..." >&2
      ${pfLoad}
    ''
  );

  launchd.daemons = {
    tor.serviceConfig = {
      ProgramArguments = afterStore torStart;
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      # Only what Tor prints before it opens its own log, and crashes.
      # launchd keeps this file open, so it must never be rotated.
      StandardOutPath = "/var/log/tor-stdout.log";
      StandardErrorPath = "/var/log/tor-stdout.log";
    };
    bind.serviceConfig = {
      ProgramArguments = afterStore (lib.getExe bindStart);
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
      # Only what named prints before it reads its configuration, and
      # crashes; launchd keeps this file open, so it must never be rotated.
      StandardOutPath = "/var/log/named-stderr.log";
      StandardErrorPath = "/var/log/named-stderr.log";
    };
    dns-over-tor-pf = lib.mkIf overTor {
      serviceConfig = {
        ProgramArguments = afterStore pfLoad;
        RunAtLoad = true;
      };
    };
    bind-captive-portal.serviceConfig = {
      ProgramArguments = afterStore (lib.getExe bindCaptivePortalWatcher);
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
    };
  };
}
