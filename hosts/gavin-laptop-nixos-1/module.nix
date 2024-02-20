{ config, lib, pkgs, ... }:

{
  imports = [ ../common/gnome-x11.nix ../common/syncthing.nix ];
  environment.systemPackages = with pkgs; [
    vlc
    libsForQt5.kdenlive
    gimp
    obs-studio
    glaxnimate
    libreoffice-qt
  ];
}
