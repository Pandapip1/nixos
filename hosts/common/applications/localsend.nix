{ config, lib, pkgs, ... }:

{
  imports = [
    ../services/avahi.nix
  ];
  environment.systemPackages = with pkgs; [
    localsend
  ];
}
