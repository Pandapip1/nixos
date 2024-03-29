{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-software-center.url = "github:snowfallorg/nix-software-center";
    nixos-conf-editor.url = "github:snowfallorg/nixos-conf-editor";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, ... }@args:
    let
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      pkgs-unstable = import nixpkgs-unstable { inherit system; config.allowUnfree = true; };
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
            pkgs-unstable = pkgs-unstable;
          };
          modules = [
            ./hosts/common/common.nix
            "${hostsDir}/${hostname}/hardware-configuration.nix"
            "${hostsDir}/${hostname}/module.nix"
          ];
        };
      }) hosts);
    };
}
