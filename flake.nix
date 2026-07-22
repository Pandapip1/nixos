{
  description = "A NixOS configuration with per-FQDN modifications";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    disko = {
      # https://github.com/nix-community/disko/pull/1277
      url = "github:AlexLov/disko/fix-vmTools-overried";
      # url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:nix-community/flake-compat";
    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
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
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        gitignore.follows = "gitignore";
      };
    };
    denix = {
      url = "github:yunfachi/denix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-lib.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        # TODO: Get rid of nix-darwin?
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };
    nixowos = {
      url = "github:yunfachi/nixowos";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
        flake-parts.follows = "flake-parts";
        # denix.follows = "denix"; # TODO: Uses outdated denix it seems
        git-hooks.follows = "pre-commit-hooks";
        # TODO: systems
        # TODO: nuschtos-search
      };
    };
    nixos-rk3588 = {
      url = "github:Pandapip1/nixos-rk3588/housekeeping-2026-07-22";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      hostsDir = self.outPath + "/hosts";
      modulesDir = self.outPath + "/modules";
      hosts = lib.packagesFromDirectoryRecursive {
        callPackage = path: _: path;
        directory = hostsDir;
      };
      modules = lib.collect (x: !lib.isAttrs x) (
        lib.packagesFromDirectoryRecursive {
          callPackage = path: _: path;
          directory = modulesDir;
        }
      );
      inputModules = with inputs; [
        nixowos.nixosModules.default
        home-manager.nixosModules.default
      ];
      inputOverlays = with inputs; [
        comma.overlays.default
        nix-index-database.overlays.nix-index
        nur.overlays.default
      ];
    in
    {
      legacyPackages = lib.listToAttrs (
        map (system: {
          name = system;
          value = lib.mapAttrs' (
            fqdn: _:
            let
              hostName = lib.head (lib.splitString "." fqdn);
            in
            {
              name = hostName;
              value = {
                install-nixos =
                  inputs.nixpkgs.legacyPackages.${system}.writeShellScriptBin "install-nixos-${hostName}"
                    ''
                      set -euox pipefail
                      if [ "$(id -u)" -ne 0 ]; then
                        if command -v sudo &>/dev/null; then
                          exec sudo "$0" "$@"
                        else
                          echo "Error: must be run as root (no sudo or run0 found)" >&2
                          exit 1
                        fi
                      fi
                      ${lib.getExe inputs.disko.packages.${system}.default} \
                        --mode destroy,format,mount \
                        ${
                          lib.strings.concatStringsSep " \\\n" (
                            lib.mapAttrsToList (
                              name: value: "--arg ${name} '(builtins.getFlake (toString ./.)).inputs.${name}'"
                            ) inputs
                          )
                        } \
                        ${self}/hosts/${system}/${fqdn}/disko-config.nix
                      nixos-install --flake '.#${hostName}' --no-root-passwd
                    '';
                mount-installation =
                  inputs.nixpkgs.legacyPackages.${system}.writeShellScriptBin "mount-installation-${hostName}"
                    ''
                      set -euox pipefail
                      ${lib.getExe inputs.disko.packages.${system}.default} \
                        --mode mount \
                        ${
                          lib.strings.concatStringsSep " \\\n" (
                            lib.mapAttrsToList (
                              name: value: "--arg ${name} '(builtins.getFlake (toString ./.)).inputs.${name}'"
                            ) inputs
                          )
                        } \
                        ${self}/hosts/${system}/${fqdn}/disko-config.nix
                    '';
                inherit (self.nixosConfigurations.${hostName}.config.system.build)
                  diskoImages
                  ;
              };
            }
          ) hosts.${system};
        }) (lib.attrNames hosts)
      );

      nixosConfigurations = lib.mergeAttrsList (
        map (
          system:
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
                specialArgs = inputs;
                modules = [
                  {
                    networking = {
                      inherit hostName domain;
                    };
                    nixpkgs = {
                      hostPlatform = {
                        inherit system;
                      };
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
        ) (lib.attrNames hosts)
      );
    };
}
