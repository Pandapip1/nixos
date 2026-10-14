{
  config,
  lib,
  pkgs,
  ...
}:

let
  toOption =
    indent: name: value:
    "${indent}${name}: ${toString value}";
  toConf =
    indent: name: value:
    if builtins.isFloat value then
      toOption indent name (builtins.toJSON value)
    else if builtins.isInt value then
      toOption indent name (toString value)
    else if builtins.isBool value then
      toOption indent name (lib.boolToYesNo value)
    else if builtins.isString value then
      toOption indent name value
    else if builtins.isList value then
      lib.concatMapStringsSep "\n" (toConf indent name) value
    else if builtins.isAttrs value then
      lib.concatStringsSep "\n" (
        [ "${indent}${name}:" ] ++ lib.mapAttrsToList (toConf "${indent}  ") value
      )
    else
      throw "Unsupported Unbound setting type for ${name}";

  settings = lib.recursiveUpdate config.localDns.unboundSettings {
    server = {
      username = ''""'';
      chroot = ''""'';
      directory = "/var/run/unbound";
      pidfile = ''""'';
      do-daemonize = false;
      root-hints = "/var/run/dns/root.hints";
    };
  };
  unboundConfig = pkgs.writeText "unbound.conf" (
    lib.concatStringsSep "\n" (lib.mapAttrsToList (toConf "") settings) + "\n"
  );
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
  unboundStart = pkgs.writeShellApplication {
    name = "unbound-start";
    runtimeInputs = with pkgs; [
      coreutils
      dnsutils
      gawk
      unbound
    ];
    text = ''
      set -euo pipefail

      install -d -m 755 /var/run/opennic /var/run/dns /var/run/unbound
      tmp=$(mktemp)
      success=0

      for server in 2001:470:4212:10:0:100:53:10 161.97.219.84 168.119.153.26; do
        if dig . NS "@$server" +time=2 +tries=1 +noall +answer +additional > "$tmp"; then
          success=1
          break
        fi
      done

      if [[ "$success" -ne 1 ]]; then
        echo "All OpenNIC root servers failed" >&2
        exit 1
      fi

      awk '
        $4 == "NS" { print ".\\t3600\\tIN\\tNS\\t" $5 }
        $4 == "A" || $4 == "AAAA" {
          print $1 "\\t3600\\tIN\\t" $4 "\\t" $5
        }
      ' "$tmp" > /var/run/opennic/root.hints

      cat ${pkgs.dns-root-data}/root.hints /var/run/opennic/root.hints \
        | awk '!seen[$0]++' > /var/run/dns/root.hints
      rm -f "$tmp"

      exec ${pkgs.unbound}/bin/unbound -d -c ${unboundConfig}
    '';
  };
in
{
  networking.dns = [
    "127.0.0.1"
    "::1"
  ];

  environment.systemPackages = with pkgs; [
    tor
    unbound
  ];

  launchd.daemons = {
    tor.serviceConfig = {
      ProgramArguments = [ "${torStart}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
    };
    unbound.serviceConfig = {
      ProgramArguments = [ (lib.getExe unboundStart) ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
    };
  };
}
