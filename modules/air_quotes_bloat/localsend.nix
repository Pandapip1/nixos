{
  lib,
  config,
  ...
}:

{
  localsend.enable = lib.mkDefault config.services.graphical-desktop.enable;
}