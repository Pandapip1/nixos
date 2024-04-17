{ config, lib, pkgs, nixos-hardware, ... }:

{
  imports = [
    # GNOME Desktop Environment
    ../common/environments/gnome.nix
    # Services
    ../common/services/monado.nix
    # Applications
    ../common/applications/chromium.nix
    ../common/applications/codium.nix
    ../common/applications/steam.nix
    # Users
    ../common/users/gavin.nix
    # Hardware
    nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
  ];
}
