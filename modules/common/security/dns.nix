{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.localDns;
  # Addresses that are never sent through Tor: loopback (Tor's own DNSPort for
  # .onion), private and link-local networks, CGNAT (Tailscale and similar).
  privateRanges4 = [
    "127.0.0.0/8"
    "10.0.0.0/8"
    "172.16.0.0/12"
    "192.168.0.0/16"
    "169.254.0.0/16"
    "100.64.0.0/10"
  ];
  privateRanges6 = [
    "::1/128"
    "fc00::/7"
    "fe80::/10"
  ];
  torTransPort = 9040;
  # Tor's DNSPort, for .onion only (see the "onion" zone).
  torDnsPort = 9053;
  openNicZones = [
    "bbs" "chan" "cyb" "dyn" "epic" "geek" "gopher" "indy" "libre"
    "neo" "o" "opennic.glue" "oss" "oz" "parody"
  ];
  openNicForwardZones = [ "null" "pirate" ];
  openNicTier1 = [
    "161.97.219.84"
    "104.168.144.17"
    "163.172.168.171"
    "94.103.153.176"
    "207.192.71.13"
    "178.63.116.152"
    "209.141.36.19"
    "188.226.146.136"
  ];
  furServers = [
    "188.40.132.212"
    "178.63.26.172"
    "178.63.145.230"
    "151.236.24.112"
    "2a01:4f8:221:1e01::1f:12"
  ];
  captivePortalZones = [
    "captive.apple.com"
    "www.apple.com"
    "connectivitycheck.gstatic.com"
    "connectivitycheck.android.com"
    "connectivitycheck.android.google.com"
    "clients3.google.com"
    "msftconnecttest.com"
    "msftncsi.com"
    "detectportal.firefox.com"
    "network-test.debian.org"
    "nmcheck.gnome.org"
    "connectivity-check.ubuntu.com"
  ];
  addresses = servers: lib.concatMapStrings (server: "${server};\n") servers;
  insecureZones =
    [ "onion" ] ++ openNicZones ++ openNicForwardZones ++ [ "fur" ] ++ captivePortalZones;
  testRndcKey = pkgs.writeText "rndc.key" ''
    key "rndc-key" {
      algorithm hmac-sha256;
      secret "Ini0XSebb9LrYz7zprobBLZ2iwBEK5S9vh9zj/DozR8=";
    };
  '';
  makeBindConfig =
    {
      directory,
      rndcKeyFile ? null,
      # Where named logs: "syslog daemon" (journal on NixOS), "stderr", or a
      # file clause (file "path" versions N size S).
      logDestination ? "syslog daemon",
      # Where the query-errors channel goes; a file channel needs a file of
      # its own, since each file channel rotates independently.
      errorLogDestination ? logDestination,
    }:
    let
      unchecked = pkgs.writeText "named.conf.unchecked" ''
        ${lib.optionalString (rndcKeyFile != null) ''
          include "${rndcKeyFile}";
          controls {
            inet 127.0.0.1 allow { localhost; } keys { "rndc-key"; };
          };
        ''}

        include "${directory}/captive-portal.conf";

        logging {
          channel main {
            ${logDestination};
            severity info;
            print-time yes;
            print-category yes;
            print-severity yes;
          };
          category default { main; };
          # Why each SERVFAIL happened. BIND logs these at debug level 1, so
          # they get their own channel; nothing else is logged at debug.
          channel errors {
            ${errorLogDestination};
            severity debug 1;
            print-time yes;
            print-category yes;
            print-severity yes;
          };
          category query-errors { errors; };
          # One line per unreachable or misbehaving server; mostly noise.
          category lame-servers { null; };
        };

        options {
          directory "${directory}";
          pid-file "${directory}/named.pid";
          session-keyfile "${directory}/session.key";
          managed-keys-directory "${directory}";

          listen-on port 53 { 127.0.0.1; };
          listen-on-v6 port 53 { ::1; };
          allow-query { localhost; };
          allow-recursion { localhost; };
          recursion yes;

          dnssec-validation auto;
          validate-except {
            ${lib.concatMapStrings (zone: "${zone};\n") insecureZones}
          };

          minimal-responses yes;
          qname-minimization relaxed;
          prefetch 2 9;
          # Also refresh a cached answer in the background once it is this far
          # (in percent) through its TTL, still answering from the cache (our
          # BIND patch); see localDns.prefetchPercent.
          prefetch-percent ${toString cfg.prefetchPercent};
          # BIND owns caching. When recursion fails, answer from the expired
          # cache rather than failing. stale-cache-enable defaults to no, and
          # without it no expired records are kept for stale-answer-enable to
          # serve.
          stale-cache-enable yes;
          stale-answer-enable yes;
          # Answer from stale data straight away (refreshing it in the
          # background) and give it TTL 0 so clients don't keep it. BIND 9.20
          # only accepts 0 here anyway; 0 for the TTL needs our patch.
          stale-answer-client-timeout 0;
          stale-answer-ttl 0;
          # Don't synthesise answers from cached NSEC ranges. With stale
          # answers served immediately, a stale covering NSEC under an expired
          # delegation made BIND report "recursion loop detected" and SERVFAIL
          # every retry without resolving again (js.hcaptcha.com, 2026-11-16).
          synth-from-dnssec no;
          # Don't remember SERVFAILs; retry recursion on the next query.
          servfail-ttl 0;
          max-stale-ttl 1d;
          # Our copies of the OpenNIC zones are for us only; don't announce them.
          notify no;
${lib.optionalString cfg.recurseOverTor ''
          # Each step of a lookup is a new TCP connection through Tor, so a full
          # resolution (with its DNSSEC lookups) can take well over the default
          # 10 s. Allow the maximum.
          resolver-query-timeout 30000;
          # Each query to a server is given its measured RTT plus this long
          # (ms) before BIND tries the next server. Tor accepts BIND's TCP
          # connection at once and only then connects to the server, so the
          # first answer on a new connection takes Tor's stream setup: over
          # a warm circuit 0.7 s typically and 2 s for 90% (measured
          # 2026-11-17; the rest never connect). Upstream allows 1 s, and
          # tcp-only servers got none (an 800 ms timeout; our BIND patch).
          resolver-tcp-allowance 3000;
          # Keep TCP connections to each server open for up to 2 minutes (the
          # maximum, in tenths of a second) so repeat queries reuse them
          # instead of opening a new connection through Tor each time.
          tcp-reuse-timeout 1200;
        ''}        };

        ${lib.concatMapStrings (zone: ''
          zone "${zone}" {
            type secondary;
            file "slaves/${zone}.zone";
            primaries {
              ${addresses openNicTier1}
            };
          };
        '') openNicZones}

        ${lib.concatMapStrings (zone: ''
          zone "${zone}" {
            type forward;
            forward only;
            forwarders {
              ${addresses openNicTier1}
            };
          };
        '') openNicForwardZones}

        zone "fur" {
          type forward;
          forward only;
          forwarders {
            ${addresses furServers}
          };
        };

        ${lib.optionalString cfg.recurseOverTor ''
          # Recursion goes through Tor (see the firewall rules in the nixos and
          # darwin dns modules). Tor only carries TCP, and its transparent proxy
          # is IPv4 here, so: TCP to every public server, no public IPv6
          # servers, and plain DNS on private networks. The captive-portal
          # forwarders get their own exceptions in captive-portal.conf.
          server 0.0.0.0/0 { tcp-only yes; };
          server ::/0 { bogus yes; };
          ${lib.concatMapStrings (r: "server ${r} { tcp-only no; };\n") privateRanges4}
          ${lib.concatMapStrings (r: "server ${r} { bogus no; };\n") privateRanges6}
        ''}

        # .onion only: Tor resolves onion names itself. Never a fallback for
        # other names, which BIND resolves itself.
        zone "onion" {
          type forward;
          forward only;
          forwarders { 127.0.0.1 port ${toString torDnsPort}; };
        };
      '';
    in
    # Check against the patched BIND that will run it (it has extra options).
    pkgs.runCommand "named.conf" { nativeBuildInputs = [ pkgs.bind-resolver ]; } ''
      cp ${unchecked} named.conf.check
      substituteInPlace named.conf.check \
        --replace-fail '${directory}' "$TMPDIR"
      touch "$TMPDIR/captive-portal.conf"
      ${lib.optionalString (rndcKeyFile != null) ''
        substituteInPlace named.conf.check \
          --replace-fail '${rndcKeyFile}' '${testRndcKey}'
      ''}
      named-checkconf named.conf.check
      cp ${unchecked} "$out"
    '';
in
{
  options.localDns.bindConfig = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    internal = true;
  };

  options.localDns.captivePortalZones = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    readOnly = true;
    internal = true;
  };

  options.localDns.recurseOverTor = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Send BIND's recursive queries through Tor's transparent proxy. When Tor
      is unavailable, recursion fails rather than going out directly; only
      the captive-portal probe domains use the network's own DNS.
    '';
  };

  options.localDns.prefetchPercent = lib.mkOption {
    type = lib.types.ints.between 0 100;
    default = 80;
    description = ''
      Refresh a cached record in the background once this percentage of its
      TTL has passed, while still answering from the cache. 0 turns it off
      (BIND's ordinary seconds-based prefetch still applies).
    '';
  };

  options.localDns.namedArgs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    readOnly = true;
    internal = true;
    description = "Extra command-line arguments for named.";
  };

  options.localDns.firewall = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    internal = true;
    description = "Address ranges and the Tor port the DNS-over-Tor firewall rules need.";
  };

  config.localDns = {
    bindConfig = makeBindConfig;
    inherit captivePortalZones;
    firewall = {
      inherit privateRanges4 privateRanges6 torTransPort torDnsPort;
    };
    # Reusable upstream TCP connections are kept per worker thread, so with
    # one worker every query shares them; that matters when each new
    # connection goes through Tor. A local resolver needs no more.
    namedArgs = lib.optionals cfg.recurseOverTor [
      "-n"
      "1"
    ];
  };
}
