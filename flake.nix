{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    getFlake.url = "github:ursi/get-flake";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:nix-community/flake-compat";
    nixos-hardware.url = "github:nixos/nixos-hardware";
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
            map (hostname: {
              name = hostname;
              value =
                let
                  pkgs-unpatched = import nixpkgs { inherit system; };
                  nixpkgs-patched-source = pkgs-unpatched.applyPatches {
                    name = "nixpkgs-patched-source";
                    src = nixpkgs;
                    patches =
                      let
                        fetchpatch = pkgs-unpatched.fetchpatch;
                      in
                      [
                      ];
                  };
                  nixpkgs-patched = getFlake "${nixpkgs-patched-source}";
                  modules = map (s: "${modulesDir}/${s}") (builtins.attrNames (builtins.readDir modulesDir));
                in
                nixpkgs-patched.lib.nixosSystem {
                  inherit system;
                  specialArgs = inputs // {
                    inherit system hostname;
                  };
                  modules = [
                    ./common.nix
                    (hostsDir + "/${system}/${hostname}.nix")
                    inputs.nur.modules.nixos.default
                    inputs.nix-index-database.nixosModules.nix-index
                    {
                      nixpkgs.hostPlatform = system;
                    }
                  ] ++ modules;
                };
            }) hosts."${system}"
          )
        ) (builtins.attrNames hosts)
      );
    };
}
