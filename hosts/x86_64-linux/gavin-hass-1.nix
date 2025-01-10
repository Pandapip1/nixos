{ ... }:

{
  imports = [
    # Services
    ../../services/avahi.nix
    ../../services/nebula.nix
    ../../services/hass.nix
    # Users
    ../../users/gavin.nix
  ];
}
