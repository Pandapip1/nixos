{ ... }:

{
  imports = [
    # Services
    ../services/nebula.nix
    ../services/openssh.nix
    # Users
    ../users/gavin.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
