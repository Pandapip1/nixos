{ config, lib, pkgs, ... }:

{
  imports = [ ../common/gnome-wayland.nix ../common/syncthing.nix ../common/chromium.nix ];
  environment.systemPackages = with pkgs; [
    vlc
    libsForQt5.kdenlive
    gimp
    obs-studio
    glaxnimate
    libreoffice-qt
  ];
}
