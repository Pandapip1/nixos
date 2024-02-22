{ config, lib, pkgs, ... }:

{
  imports = [ ../common/gnome-wayland.nix ../common/syncthing.nix ../common/chromium.nix ../common/codium.nix ];
  environment.systemPackages = with pkgs; [
    vlc
    libsForQt5.kdenlive
    gimp
    obs-studio
    glaxnimate
    libreoffice-qt
    wl-clipboard
    waydroid
    immersed-vr
  ];
  virtualisation.waydroid.enable = true;
  virtualisation.lxd.enable = true;
}
