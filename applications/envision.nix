{ system, pkgs, envision, ... }:

{
  # Enable dependencies
  imports = [
    ../services/avahi.nix
  ];

  environment.systemPackages = [
    envision.packages.${system}.default
    pkgs.android-tools
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
