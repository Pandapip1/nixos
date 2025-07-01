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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    stevenblack-hosts = {
      url = "github:Stevenblack/hosts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comma = {
      url = "github:Pandapip1/comma/command-not-found-handle";
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
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    srvos = {
      url = "github:nix-community/srvos";
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
      inherit (nixpkgs) lib;
      hostsDir = "${self}/hosts";
      modulesDir = "${self}/modules";
      hosts = lib.mapAttrs (
        system: _:
        map (s: lib.substring 0 (lib.stringLength s - 4) s) (
          lib.attrNames (builtins.readDir "${hostsDir}/${system}")
        )
      ) (builtins.readDir hostsDir);
      systems = lib.attrNames hosts;
      modules = map (s: "${modulesDir}/${s}") (lib.attrNames (builtins.readDir modulesDir));
      inputModules = with inputs; [
        stevenblack-hosts.nixosModule
      ];
      inputOverlays = with inputs; [
        comma.overlays.default
        nix-index-database.overlays.nix-index
        nur.overlays.default
      ];

      concatAttrSets = attrs: lib.foldl' (a: b: a // b) { } attrs;
    in
    {
      nixosConfigurations = concatAttrSets (
        map (
          system:
          builtins.listToAttrs (
            map (
              fqdn:
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
                      "${self}/common.nix"
                      "${hostsDir}/${system}/${fqdn}.nix"
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
