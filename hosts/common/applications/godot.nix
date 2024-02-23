{ config, lib, pkgs, ... }:

{
  imports = [
    ../services/monado.nix # OpenXR runtime
  ];
  environment.systemPackages = with pkgs; [
    godot_4
  ];
}
