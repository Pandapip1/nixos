{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    getFlake.url = "github:ursi/get-flake";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:nix-community/flake-compat";
    nixos-hardware.url = "github:Pandapip1/nixos-hardware/general-intel-gpu-compat-stuff-v2";
    comma = {
      url = "github:Pandapip1/comma/command-not-found-handle";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      getFlake,
      flake-utils,
      ...
    }@inputs:
    let
      hostsDir = ./hosts;
      modulesDir = ./modules;
      hosts = map (s: builtins.substring 0 (builtins.stringLength s - 4) s) (
        builtins.attrNames (builtins.readDir hostsDir)
      );
    in
    {
      nixosConfigurations = builtins.listToAttrs (
        map (hostname: {
          name = hostname;
          value =
            let
              system = (import (hostsDir + "/${hostname}.nix") inputs).nixpkgs.hostPlatform;
              pkgs-unpatched = import nixpkgs { inherit system; };
              nixpkgs-patched-source = pkgs-unpatched.applyPatches {
                name = "nixpkgs-patched-source";
                src = nixpkgs;
                patches =
                  let
                    fetchpatch = pkgs-unpatched.fetchpatch;
                  in
                  [
                    (fetchpatch {
                      name = "init-cosmic-wallpapers.patch";
                      url = "https://github.com/NixOS/nixpkgs/compare/master..6fdc38a038528f57ab2e48802a92c28f432614c9.patch";
                      hash = "sha256-FaRTb7c9tHRq6pfItvmmsi4gWA9d4PAWME623YQRMkM=";
                    })
                  ];
              };
              nixpkgs-patched = getFlake "${nixpkgs-patched-source}";
              modules = map (s: "${modulesDir}/${s}") (
                builtins.attrNames (builtins.readDir modulesDir)
              );
            in
            nixpkgs-patched.lib.nixosSystem {
              inherit system;
              specialArgs = inputs // {
                inherit system hostname;
              };
              modules = [
                ./common.nix
                (hostsDir + "/${hostname}.nix")
                inputs.home-manager.nixosModules.default
                inputs.nixos-cosmic.nixosModules.default
              ] ++ modules;
            };
        }) hosts
      );
    };
}
