{ config, lib, pkgs, inputs, pkgs-unstable, ... }:
{
  environment.systemPackages = with pkgs-unstable; [
    pmbootstrap
  ];
}
