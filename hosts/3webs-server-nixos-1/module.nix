{ config, lib, pkgs, ... }:

{
  imports = [
    # Services
    ../common/services/syncthing.nix
    ../common/services/nebula.nix
    ../common/services/gpg.nix
    ../common/services/openssh.nix
    # Users
    ../common/users/gavin.nix
  ];
}
