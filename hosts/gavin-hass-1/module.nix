{ config, lib, pkgs, ... }:

{
  imports = [
    # Services
    ../common/services/avahi.nix
    ../common/services/nebula.nix
    ../common/services/hass.nix
    # Users
    ../common/users/gavin.nix
  ];
}
