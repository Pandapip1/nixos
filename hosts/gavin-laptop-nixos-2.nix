{ config, lib, pkgs, ... }:

{
  imports = [
    # GNOME Desktop Environment
    ../environments/gnome.nix
    # Services
    ../services/syncthing.nix
    ../services/nextcloud.nix
    ../services/nebula.nix
    ../services/waydroid.nix
    ../services/gpg.nix
    # Applications
    ../applications/chromium.nix
    ../applications/vector.nix
    ../applications/codium.nix
    ../applications/envision.nix
    ../applications/telescope.nix
    ../applications/localsend.nix
    # Users
    ../users/gavin.nix
  ];
}
