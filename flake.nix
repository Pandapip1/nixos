{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    nix-software-center.url = "github:snowfallorg/nix-software-center";
    nixos-conf-editor.url = "github:snowfallorg/nixos-conf-editor";
  };

  outputs = { self, nixpkgs, flake-utils, agenix, ... }@args:
    let
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      system = "x86_64-linux";
      hostsDir = ./hosts;
      hosts = builtins.attrNames (builtins.readDir hostsDir);
    in {
      nixosConfigurations = builtins.listToAttrs (map (hostname: {
        name = hostname;
        value = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = args // {
            hostname = hostname;
            pkgs = pkgs;
          };
          modules = [
            ./hosts/common/common.nix
            "${hostsDir}/${hostname}/hardware-configuration.nix"
            "${hostsDir}/${hostname}/module.nix"
            agenix.nixosModules.default
          ];
        };
      }) hosts);
    };
}
