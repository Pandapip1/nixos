# Extreme settings for powersaving
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options = {
    defaults.powersaving = lib.mkEnableOption "powersaving defaults" // {
      # default = true;
    };
  };

  config = lib.mkIf config.defaults.powersaving {
    services.autoaspm.enable = true;
    powerManagement.powertop.enable = true;
  };
}
