{
  description = "Unified flake";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-23.11";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    {
      nixosConfigurations = let
        baseConfiguration = ./configuration.nix;
        makeConfig = { system, name, extraConfig }: 
          let
            pkgs = import nixpkgs { inherit system; };
            config = import baseConfiguration { inherit pkgs; };
          in
            pkgs.nixos.lib.nixosSystem {
              inherit system;
              modules = [
                ({
                  imports = [ baseConfiguration ];
                  networking.hostName = name;
                } // extraConfig)
              ];
            };
      in {
        "gavin-laptop-nixos-1" = makeConfig {
          system = "x86_64-linux";
          name = "gavin-laptop-nixos-1";
          extraConfig = { };
        };
      };
    };
}
