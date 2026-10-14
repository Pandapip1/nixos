{
  lib,
  config,
  ...
}:

{
  services.gnome.gnome-settings-daemon.enable = lib.mkDefault config.services.graphical-desktop.enable;
}
