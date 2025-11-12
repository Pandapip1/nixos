{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./hass.nix
  ];

  system.stateVersion = "25.11";
}
