{ ... }:

{
  imports = [
    # Services
    ../../services/nebula.nix
    ../../services/openssh.nix
    # Users
    ../../users/gavin.nix
  ];
}
