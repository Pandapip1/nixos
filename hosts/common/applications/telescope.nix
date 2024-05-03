{ config, lib, pkgs, telescope, ... }:

{
  environment.systemPackages = with pkgs; [
    telescope.apps.${system}.default
    telescope.apps.${system}.flatscreen
  ];
}
