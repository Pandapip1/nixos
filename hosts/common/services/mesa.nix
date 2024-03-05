{ config, lib, pkgs, nix-software-center, nixos-conf-editor, ... }:

{
  hardware.opengl = {
    enable = true;
    package = pkgs.mesa.drivers;
    package32 = pkgs.pkgsi686Linux.mesa.drivers;
    driSupport32Bit = true;
  };
}
