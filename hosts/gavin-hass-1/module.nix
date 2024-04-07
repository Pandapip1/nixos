{ config, lib, pkgs, ... }:

{
  imports = [
    # Services
    ../common/services/nebula.nix
    ../common/services/homeassistant.nix
    # Users
    ../common/users/gavin.nix
  ];
}
