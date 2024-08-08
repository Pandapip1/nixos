{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master"; # WARNING: The bleeding edge is sharp!
    getFlake.url = "github:ursi/get-flake";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vector = {
      url = "github:3webs-org/vector";
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
                      name = "init-cups-idprt.patch";
                      url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/308317.patch";
                      hash = "sha256-HiJ+KJhTe3oeu5ftl7rbXecMTa2rav2ECg+SbLBk/N4=";
                    })
                    (fetchpatch {
                      name = "init-stardust-xr-server.patch";
                      url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/324375.patch";
                      hash = "sha256-Eeqb4OEeC1zBCqeDMokc/yjOyVCCAmgmYRDNce609Gg=";
                    })
                    (fetchpatch {
                      name = "init-stardust-xr-flatland.patch";
                      url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/324395.patch";
                      hash = "sha256-VtIC40bHzlx9iYktttd7nsi3WKs3h00u3OalSTguNbc=";
                    })
                    (fetchpatch {
                      name = "init-stardust-xr-kiara.patch";
                      url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/324404.patch";
                      hash = "sha256-jt5iiof2o4GULIhwzuXtUGQbrh0fM8LKMjUut7huDIo=";
                    })
                    (fetchpatch {
                      name = "fix-minecraft.patch";
                      url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/326374.patch";
                      hash = "sha256-w8ty0a3sHKqHI1basWS+ah1/ultw7MEiAoi8w6XANdc=";
                    })
                  ];
              };
              nixpkgs-patched = getFlake "${nixpkgs-patched-source}";
              pkgs = (import nixpkgs-patched { inherit system; config.allowUnfree = true; }); # TODO: Is there a way to put allowUnfree in common.nix?
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
              ];
            };
        }) hosts
      );
    };
}
