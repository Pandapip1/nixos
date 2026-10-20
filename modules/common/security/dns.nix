{
  lib,
  pkgs,
  ...
}:

let
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
          stale-answer-enable yes;
          stale-answer-client-timeout 1800;
          max-stale-ttl 1d;
        };

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

        zone "onion" {
          type forward;
          forward only;
          forwarders { 127.0.0.1 port 9053; };
        };
      '';
    in
    pkgs.runCommand "named.conf" { nativeBuildInputs = [ pkgs.bind ]; } ''
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

  config.localDns = {
    bindConfig = makeBindConfig;
    inherit captivePortalZones;
  };
}
