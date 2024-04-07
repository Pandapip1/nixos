{ config, lib, pkgs, ... }:

{
  imports = [
    # Services
    ../common/services/nebula.nix
    ../common/services/hass.nix
    # Users
    ../common/users/gavin.nix
  ];
}
