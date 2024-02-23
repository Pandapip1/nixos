{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cmake
    ninja
  ];
}
