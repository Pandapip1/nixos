{
  lib,
  config,
  ...
}:

{
  programs.firefox = {
    enable = lib.mkDefault config.services.graphical-desktop.enable;
  };
}
