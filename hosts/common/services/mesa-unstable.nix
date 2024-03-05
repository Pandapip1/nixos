{ config, lib, pkgs, pkgs-unstable, ... }:

{
  hardware.opengl = {
    enable = true;
    package = pkgs-unstable.mesa.drivers;
    package32 = pkgs-unstable.pkgsi686Linux.mesa.drivers;
    driSupport32Bit = true;
  };
}
