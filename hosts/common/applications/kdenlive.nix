{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    libsForQt5.kdenlive
    glaxnimate
  ];
}
