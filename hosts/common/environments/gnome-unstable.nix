{ config, lib, pkgs-unstable, ... }:

{
  # Enable dependencies
  imports = [
    ../services/mesa-unstable.nix
    ./gnome.nix
  ];

  environment.systemPackages = with pkgs-unstable.gnome; [
    gnome-shell
    gdm
  ];
}
