{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.optimizations.powersaving.enable = lib.mkEnableOption "power saving optimizations";

  config = lib.mkIf config.optimizations.powersaving.enable {
    services.autoaspm.enable = true;
    powerManagement.powertop.enable = true;
  };
}
