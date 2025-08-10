{
  lib,
  pkgs,
  config,
  ...
}:

{
  environment.systemPackages = lib.optional (
    config.programs.gnupg.agent.enable && config.programs.gnupg.agent.pinentryPackage != null
  ) config.programs.gnupg.agent.pinentryPackage;
}
