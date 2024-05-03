{ config, lib, pkgs, envision, ... }:

{
  # Enable dependencies
  imports = [
    ../services/avahi.nix
  ];

  environment.systemPackages = with pkgs; [
    envision.packages.${system}.default
  ];
  networking.firewall = {
    allowedTCPPorts = [
      9757 # WiVRN
    ];
    allowedUDPPorts = [
      9757 # WiVRN
    ];
  };
}
