{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./hass.nix
  ];

  services.openssh = {
    enable = true;
  };

  services.nebula.networks.nebula0.enable = true;

  system.stateVersion = "25.11";
}
