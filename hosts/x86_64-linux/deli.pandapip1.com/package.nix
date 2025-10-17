{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  services.openssh = {
    enable = true;
  };

  system.stateVersion = "25.11";
}
