{
  lib,
  config,
  ...
}:

{
  programs.gnome-disks.enable = lib.mkDefault config.services.graphical-desktop.enable;
}
