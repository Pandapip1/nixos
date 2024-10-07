{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    getFlake.url = "github:ursi/get-flake";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    comma = {
      url = "github:Pandapip1/comma/command-not-found-handle";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
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
                      name = "fix-qgc.patch";
                      url = "https://github.com/NixOS/nixpkgs/compare/master..e990c276a96d1b1013299c0b0d05af4b2cef2835.patch";
                      hash = "sha256-WmBpQ89t/jDuOk2QrX54rPPDDMLpzZerFKN1a7imwsU=";
                    })
                    (fetchpatch {
                      name = "init-vscode-markdown-to-pdf.patch";
                      url = "https://github.com/NixOS/nixpkgs/compare/master..1bbfbb0680e52c821f8b706571edeefb990d86c9.patch";
                      hash = "sha256-hMSx+55pOffThkqXW32xR/eS9olHseJwARAdGGlTjIA=";
                    })
                  ];
              };
              nixpkgs-patched = getFlake "${nixpkgs-patched-source}";
              pkgs = (import nixpkgs-patched {
                inherit system;
                config = {
                  allowUnfree = true;
                };
              }); # TODO: Is there a way to put allowUnfree in common.nix?
              modules = map (s: "${modulesDir}/${s}") (
                builtins.attrNames (builtins.readDir modulesDir)
              );
            in
            nixpkgs-patched.lib.nixosSystem {
              inherit system;
              specialArgs = inputs // {
                inherit system hostname pkgs;
              };
              modules = [
                ./common.nix
                (hostsDir + "/${hostname}.nix")
                inputs.home-manager.nixosModules.default
              ] ++ modules;
            };
        }) hosts
      );
    };
}
