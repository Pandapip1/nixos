{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }: 
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {};
        };
        hostsDir = ./hosts;
        hosts = builtins.readDir hostsDir;
        mkHost = hostname:
          { config, lib, ... }: {
            imports = [
              ./hardware-configuration.nix
              ./common.nix
              "${hostsDir}/${hostname}.nix"
            ];
            networking.hostName = hostname;
          };
      in
      {
        nixosConfigurations = builtins.mapAttrs' (name: path: nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ (mkHost name) ];
        }) hosts;
      }
    );
}
