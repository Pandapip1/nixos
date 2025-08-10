{
  lib,
  pkgs,
  config,
  ...
}:

lib.mkIf (config.programs.gnupg.agent.enable && config.programs.gnupg.agent.pinentryPackage != null)
  {
    environment.systemPackages = [
      (pkgs.writeScriptBin "pinentry" ''exec ${lib.getBin config.programs.gnupg.agent.pinentryPackage} "$@"'')
    ];
  }
