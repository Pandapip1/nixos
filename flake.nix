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
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:nix-community/flake-compat";
    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
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
        denix.follows = "denix";
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
      modules = lib.collect (
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
                      ${
                        lib.getExe inputs.disko.packages.${system}.default
                      } --mode destroy,format,mount ${self}/hosts/${system}/${fqdn}/disko-config.nix
                      nixos-install --flake '.#${hostName}' --no-root-passwd
                      for USER in $(nixos-enter --root /mnt -c "getent group users | cut -d: -f4 | tr ',' '\n'"); do
                        HASH=$(${lib.getExe inputs.nixpkgs.legacyPackages.${system}.openssl} passwd -6 $USER)
                        nixos-enter --root /mnt -c "awk -v user=\"$USER\" -v hash=\"$HASH\" -F: '
                        BEGIN { OFS=\":\" }
                        \$1 == user {
                            \$2 = hash
                        }
                        { print }
                        ' /etc/shadow" | nixos-enter --root /mnt -c "tee /etc/shadow" > /dev/null
                        nixos-enter --root /mnt -c "chage -d 0 $USER"
                      done
                    '';
                mount-installation =
                  inputs.nixpkgs.legacyPackages.${system}.writeShellScriptBin "mount-installation-${hostName}"
                    ''
                      set -euox pipefail
                      ${
                        lib.getExe inputs.disko.packages.${system}.default
                      } --mode mount ${self}/hosts/${system}/${fqdn}/disko-config.nix
                    '';
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
