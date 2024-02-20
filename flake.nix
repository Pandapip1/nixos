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
    packages = flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
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
        nixosConfigurations = with pkgs.nixos.lib; {
          gavin-laptop-nixos-1 = nixosSystem {
            inherit system;
            modules = [
              (makeConfig {
                name = "gavin-laptop-nixos-1";
                extraConfig = {
                };
              })
            ];
          };
        };
      }
    );
  }
}
