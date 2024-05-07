{ config, lib, pkgs, ... }:

{
  imports = [
    # Services
    ../services/syncthing.nix
    ../services/nebula.nix
    ../services/openssh.nix
    # Users
    ../users/gavin.nix
  ];
}
