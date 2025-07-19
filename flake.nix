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
      readDirRecursive =
        path:
        lib.mapAttrs (
          path': type:
          (if (type == "directory" || type == "symlink") then readDirRecursive "${path}/${path'}" else type)
        ) (builtins.readDir path);
      initValueAtPath =
        path: value:
        if lib.length path == 0 then
          value
        else
          { ${lib.head path} = initValueAtPath (lib.tail path) value; };
      attrNamesRecursive = lib.mapAttrsToList (
        name: value:
        if lib.isAttrs value then
          lib.map (path: [ name ] ++ path) (lib.attrNamesRecursive value)
        else
          [ name ]
      );
      attrValuesRecursive =
        attrs:
        lib.foldlAttrs (
          acc: _: value:
          acc ++ (if lib.isAttrs value then attrValuesRecursive value else [ value ])
        ) [ ] attrs;
      filterAttrsRecursive' =
        filter: attrs:
        lib.mapAttrs (
          name: value:
          if lib.isAttrs value then
            filterAttrsRecursive' (path: value': filter ([ name ] ++ path) value') value
          else
            value
        ) (lib.filterAttrs (name: value: (lib.isAttrs value) || (filter [ name ] value)) attrs);
      mapAttrsRecursive' =
        mapping: attrs:
        lib.foldlAttrs (
          acc: name: value:
          let
            result =
              if lib.isAttrs value then
                mapAttrsRecursive' (path': value': mapping ([ name ] ++ path') value') value
              else
                let
                  mapped = mapping [ name ] value;
                in
                initValueAtPath mapped.path mapped.value;
          in
          lib.recursiveUpdate acc result
        ) { } attrs;
      filterAndMapAttrsRecursive' =
        filter: mapping: attrs:
        mapAttrsRecursive' mapping (filterAttrsRecursive' filter attrs);
      collectDirRecursive =
        dir:
        filterAndMapAttrsRecursive'
          (path: value: (lib.hasSuffix ".nix" (lib.last path)) && value == "regular")
          (path: _: {
            path = (lib.dropEnd 1 path) ++ [ (lib.removeSuffix ".nix" (lib.last path)) ];
            value = lib.concatStringsSep "/" ([ dir ] ++ path);
          })
          (readDirRecursive dir);
      hostsDir = "${self}/hosts";
      modulesDir = "${self}/modules";
      overlaysDir = "${self}/overlays";
      hosts = lib.mapAttrs (
        system: _:
        map (s: lib.substring 0 (lib.stringLength s - 4) s) (
          lib.attrNames (builtins.readDir "${hostsDir}/${system}")
        )
      ) (builtins.readDir hostsDir);
      systems = lib.attrNames hosts;
      modules = attrValuesRecursive (collectDirRecursive modulesDir);
      overlays = lib.map import (attrValuesRecursive (collectDirRecursive overlaysDir));
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
                          overlays = overlays ++ inputOverlays;
                        };
                      }
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
