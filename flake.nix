{
  description = "flake for gavin-laptop-nixos-1";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-23.11";
    };
    flake-utils = {
      url = "github:numtide/flake-utils"
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:  flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };

      baseConfiguration = ./configuration.nix;

      makeConfig = { name, extraConfig, ... }: pkgs.nixosConfigurations.${name} = {
        imports = [ baseConfiguration ];
        networking.hostName = name;
        ... extraConfig ...
      };
    in
    {
      nixosConfigurations = {
        gavin-laptop-nixos-1 = makeConfig {
          name = "gavin-laptop-nixos-1";
          extraConfig = {
          };
        };
      };
    }
  );
}
