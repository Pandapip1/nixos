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

  system.stateVersion = "25.11";
}
