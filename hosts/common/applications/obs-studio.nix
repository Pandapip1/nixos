{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    obs-studio
  ];
}
