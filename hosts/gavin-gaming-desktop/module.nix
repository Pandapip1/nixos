{ config, lib, pkgs, nixos-hardware, ... }:

{
  imports = [
    # GNOME Desktop Environment
    ../common/environments/gnome.nix
    # Services
    ../common/services/vr.nix
    # Applications
    ../common/applications/chromium.nix
    ../common/applications/codium.nix
    ../common/applications/steam.nix
    # Users
    ../common/users/gavin.nix
  ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
}
