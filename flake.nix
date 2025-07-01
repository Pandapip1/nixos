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
    hosts = {
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
      lib = nixpkgs.lib;
      hostsDir = ./hosts;
      modulesDir = ./modules;
      hosts = builtins.mapAttrs (
        system: _:
        map (s: builtins.substring 0 (builtins.stringLength s - 4) s) (
          builtins.attrNames (builtins.readDir (hostsDir + "/${system}"))
        )
      ) (builtins.readDir hostsDir);

      concatAttrSets =
        attrs:
        if builtins.length attrs == 0 then
          { }
        else
          concatAttrSets (builtins.tail attrs) // builtins.head attrs;
    in
    {
      nixosConfigurations = concatAttrSets (
        map (
          system:
          builtins.listToAttrs (
            map (
              fqdn:
              let
                hostname = lib.head (lib.splitString "." fqdn);
                domain =
                  if (lib.length (lib.splitString "." fqdn) == 1) then
                    null
                  else
                    lib.concatStringsSep "." (lib.tail (lib.splitString "." fqdn));
              in
              {
                name = hostname;
                value =
                  let
                    pkgs-unpatched = import nixpkgs { inherit system; };
                    #nixpkgs-patched-source = pkgs-unpatched.applyPatches {
                    #  name = "nixpkgs-patched-source";
                    #  src = nixpkgs;
                    #  patches =
                    #    let
                    #      fetchpatch = pkgs-unpatched.fetchpatch;
                    #    in
                    #    [
                    #    ];
                    #};
                    #nixpkgs-patched = getFlake "${nixpkgs-patched-source}";
                    modules = map (s: "${modulesDir}/${s}") (builtins.attrNames (builtins.readDir modulesDir));
                  in
                  #nixpkgs-patched.lib.nixosSystem {
                  nixpkgs.lib.nixosSystem {
                    inherit system;
                    specialArgs = inputs;
                    modules = [
                      {
                        networking = {
                          inherit hostname domain;
                        };
                        nixpkgs = {
                          hostPlatform = system;
                          buildPlatform = builtins.currentSystem or system;
                        };
                      }
                      ./common.nix
                      (hostsDir + "/${system}/${hostname}.nix")
                      inputs.nur.modules.nixos.default
                      inputs.nix-index-database.nixosModules.nix-index
                      inputs.hosts.nixosModule
                    ] ++ modules;
                  };
              }
            ) hosts."${system}"
          )
        ) (builtins.attrNames hosts)
      );
    };
}
