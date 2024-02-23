{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cmake
    gcc
    python3
    ninja
  ];
}
