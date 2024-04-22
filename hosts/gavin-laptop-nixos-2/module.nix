{ config, lib, pkgs, ... }:

{
  imports = [
    # GNOME Desktop Environment
    ../common/environments/gnome.nix
    # Services
    ../common/services/syncthing.nix
    ../common/services/nextcloud.nix
    ../common/services/vr.nix
    ../common/services/nebula.nix
    ../common/services/waydroid.nix
    ../common/services/gpg.nix
    # Applications
    ../common/applications/chromium.nix
    ../common/applications/codium.nix
    # Users
    ../common/users/gavin.nix
  ];
}
