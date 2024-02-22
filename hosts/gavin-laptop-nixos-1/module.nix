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
  ];
  virtualisation.waydroid.enable = true;
  system.activationScripts.waydroidMemfd = lib.stringAfter [ "var" ] ''
    mkdir -p /var/lib/waydroid
    echo -E "sys.use_memfd=true" > /var/lib/waydroid/waydroid_base.prop
  '';
}
