{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {};
      };
      hostsDir = ./hosts;
      hosts = builtins.map (x: builtins.head (builtins.match "([^.]+)\\..*" x)) (builtins.attrNames (builtins.readDir hostsDir));
    in {
      nixosConfigurations = builtins.listToAttrs (map (hostname: {
        name = hostname;
        value = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hardware-configuration.nix
            ./common.nix
            "${hostsDir}/${hostname}.nix"
          ];
          specialArgs.networking.hostName = hostname;
        };
      }) hosts);
    };
}
