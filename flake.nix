{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    nix-software-center.url = "github:snowfallorg/nix-software-center";
    nixos-conf-editor.url = "github:snowfallorg/nixos-conf-editor";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@args:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {};
      };
      hostsDir = ./hosts;
      hosts = builtins.attrNames (builtins.readDir hostsDir);
    in {
      nixosConfigurations = builtins.listToAttrs (map (hostname: {
        name = hostname;
        value = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = args // { hostname = hostname; };
          modules = [
            ./hosts/common/common.nix
            "${hostsDir}/${hostname}/hardware-configuration.nix"
            "${hostsDir}/${hostname}/module.nix"
          ];
        };
      }) hosts);
    };
}
