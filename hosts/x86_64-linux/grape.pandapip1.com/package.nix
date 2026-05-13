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

  system.stateVersion = "25.11";
}
