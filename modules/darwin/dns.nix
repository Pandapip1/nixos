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
      unbound
    ];
    text = ''
      set -euo pipefail

      install -d -m 755 /var/run/unbound
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
      # launchd can load this plist before the Nix store volume is available.
      # Wait for the store explicitly before starting Unbound.
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path /nix/store && exec ${lib.getExe unboundStart}"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 30;
    };
  };
}
