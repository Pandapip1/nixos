{ config, lib, pkgs, niri-flake, ... }:

{
  # Add niri.nixosModules.niri to the list of modules
  imports = [
    niri-flake.nixosModules.niri
  ];
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri;
}
