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
  ];

  services.openssh = {
    enable = true;
  };

  services.nebula.networks.nebula0.enable = true;

  system.stateVersion = "25.11";
}
