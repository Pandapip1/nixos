{
  lib,
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

  nix-gc.profiles.system.configurationLimit = 1; # Only one bootable at a time

  services.avahi.avahi = lib.mkForce false; # Grape should not use mDNS

  system.stateVersion = "25.11";
}
