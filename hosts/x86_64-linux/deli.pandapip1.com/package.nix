{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./linux-isos.nix
    ./jellyfin.nix
    ./nginx.nix
  ];

  services.openssh = {
    enable = true;
  };

  services.nebula.networks.nebula0.enable = true;

  system.stateVersion = "25.11";
}
