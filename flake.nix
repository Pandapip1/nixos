{
  description = "flake for gavin-laptop-nixos-1";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-23.11";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }: {
    nixosConfigurations =
      let
        pkgs = import nixpkgs { };
        baseConfiguration = ./configuration.nix;

        makeConfig = { name, extraConfig }: 
          let
            config = import baseConfiguration { inherit pkgs; };
          in
          {
            imports = [ baseConfiguration ];
            networking.hostName = name;
          } // extraConfig;
      in
      {
        gavin-laptop-nixos-1 = pkgs.nixos.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            (makeConfig {
              name = "gavin-laptop-nixos-1";
              extraConfig = {
              };
            })
          ];
        };
      };
  };
}
