{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./nginx.nix
    ./attic.nix
  ];

  services.openssh = {
    enable = true;
  };

  nix-gc.configurationLimit = 1; # Only one bootable at a time

  services.avahi.openFirewall = false; # Grape should not trust mDNS

  system.stateVersion = "25.11";
}
