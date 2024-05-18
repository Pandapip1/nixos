{ config, lib, pkgs, ... }:

{
  imports = [
    # Niri Desktop Environment
    ../environments/niri.nix
    # Services
    ../services/syncthing.nix
    ../services/nextcloud.nix
    ../services/nebula.nix
    ../services/waydroid.nix
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
