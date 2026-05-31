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

  system.stateVersion = "25.11";
}
