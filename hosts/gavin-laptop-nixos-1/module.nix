{ config, lib, pkgs, ... }:

{
  imports = [
    # GNOME Desktop Environment
    ../common/environments/gnome.nix
    # Services
    ../common/services/syncthing.nix
    ../common/services/nextcloud.nix
    ../common/services/immersed-vr.nix
    ../common/services/nebula.nix
    ../common/services/waydroid.nix
    ../common/services/gpg.nix
    # Applications
    ../common/applications/chromium.nix
    ../common/applications/codium.nix
    ../common/applications/godot.nix
    ../common/applications/vlc.nix
    ../common/applications/kdenlive.nix
    ../common/applications/gimp.nix
    ../common/applications/obs-studio.nix
    ../common/applications/libreoffice.nix
    ../common/applications/pmbootstrap.nix
    # Users
    ../common/users/gavin.nix
  ];
}
