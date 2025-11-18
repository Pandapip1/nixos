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

  system.stateVersion = "25.11";
}
