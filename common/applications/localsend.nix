{ config, lib, pkgs, ... }:

{
  imports = [
    ../services/avahi.nix
  ];
  environment.systemPackages = with pkgs; [
    localsend
  ];
  networking.firewall = {
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };
}
