{ config, lib, pkgs, nixos-hardware, ... }:

{
  imports = [
    # GNOME Desktop Environment
    ../common/environments/gnome.nix
    # Applications
    ../common/applications/chromium.nix
    ../common/applications/vector.nix
    ../common/applications/codium.nix
    ../common/applications/steam.nix
    ../common/applications/envision.nix
    ../common/applications/telescope.nix
    ../common/applications/localsend.nix
    # Users
    ../common/users/gavin.nix
  ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
}
