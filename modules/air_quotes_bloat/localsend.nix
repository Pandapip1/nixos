{
  lib,
  config,
  ...
}:

{
  programs.localsend.enable = lib.mkDefault config.services.graphical-desktop.enable;
}