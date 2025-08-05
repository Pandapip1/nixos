{
  description = "A NixOS configuration with per-FQDN modifications";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    getFlake = {
      url = "github:ursi/get-flake";
      inputs.flake-compat.follows = "flake-compat";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:nix-community/flake-compat";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
    };
    stevenblack-hosts = {
      url = "github:Stevenblack/hosts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:Pandapip1/nix-index-database/fix-comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comma = {
      url = "github:nix-community/comma";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
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
      inherit (nixpkgs) lib;
      attrValuesRecursive =
        attrs:
        lib.foldlAttrs (
          acc: _: value:
          acc ++ (if lib.isAttrs value then attrValuesRecursive value else [ value ])
        ) [ ] attrs;
      hostsDir = self.outPath + "/hosts";
      modulesDir = self.outPath + "/modules";
      hosts = lib.packagesFromDirectoryRecursive {
        callPackage = path: _: path;
        directory = hostsDir;
      };
      systems = lib.attrNames hosts;
      modules = attrValuesRecursive (
        lib.packagesFromDirectoryRecursive {
          callPackage = path: _: path;
          directory = modulesDir;
        }
      );
      inputModules = with inputs; [
        stevenblack-hosts.nixosModule
      ];
      inputOverlays = with inputs; [
        comma.overlays.default
        nix-index-database.overlays.nix-index
        nur.overlays.default
      ];
    in
    {
      nixosConfigurations = lib.mergeAttrsList (
        map (
          system:
          lib.listToAttrs (
            lib.mapAttrs' (
              fqdn: hostModulePath:
              let
                splitName = lib.splitString "." fqdn;
                hostName = lib.head splitName;
                domain =
                  if (lib.length splitName == 1) then null else lib.concatStringsSep "." (lib.tail splitName);
              in
              {
                name = hostName;
                value = lib.nixosSystem {
                  inherit system;
                  specialArgs = inputs;
                  modules =
                    [
                      {
                        networking = {
                          inherit hostName domain;
                        };
                        nixpkgs = {
                          hostPlatform = system;
                          buildPlatform = builtins.currentSystem or system;
                          overlays = inputOverlays;
                        };
                      }
                      hostModulePath
                    ]
                    ++ modules
                    ++ inputModules;
                };
              }
            ) hosts."${system}"
          )
        ) systems
      );
    };
}
