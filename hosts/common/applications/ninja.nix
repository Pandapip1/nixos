{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pkg-config
    cmake
    gcc
    python3
    ninja
  ];
}
