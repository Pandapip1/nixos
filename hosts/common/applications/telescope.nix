{ config, lib, pkgs, telescope, ... }:

{
  environment.systemPackages = with pkgs; [
    telescope.packages.${system}.default
    telescope.packages.${system}.flatscreen
  ];
}
