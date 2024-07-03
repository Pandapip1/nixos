{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    getFlake.url = "github:ursi/get-flake";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    telescope = {
      url = "github:StardustXR/telescope";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vector = {
      url = "github:3webs-org/vector";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:YaLTeR/niri/v0.1.6";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      inputs.niri-stable.follows = "niri";
    };
  };

  outputs = { self, nixpkgs, getFlake, flake-utils, ... }@inputs:
    let
      hostsDir = ./hosts;
      hosts = map (s: builtins.substring 0 (builtins.stringLength s - 4) s) (builtins.attrNames (builtins.readDir hostsDir));
    in {
      nixosConfigurations = builtins.listToAttrs (map (hostname: let
        system = "x86_64-linux";
        pkgs-unpatched = import nixpkgs { inherit system; };
        nixpkgs-patched-src = pkgs-unpatched.stdenvNoCC.mkDerivation {
          name = "nixpkgs-patched-src";
          src = nixpkgs;

          patches = let
            fetchpatch = pkgs-unpatched.fetchpatch;
          in [
            /* (fetchpatch {
              name = "buildFHSEnv-add-capability-support.patch";
              url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/309906.patch";
              hash = "sha256-RYeDc8loKq0b21/+CXco0HGduqNnFWgTeEDuyRzO0Bk=";
            }) */
            (fetchpatch {
              name = "init-cups-idprt.patch";
              url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/308317.patch";
              hash = "sha256-0kZDccC4WaKL+y3QEypQjeRx3AO1mE2wZqPyN8b6bVE=";
            })
            (fetchpatch {
              name = "init-envision.patch";
              url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/321015.patch";
              hash = "sha256-v18FDPDmAKViBFO6UnPDgpQN4ENvhssEafXnZGstEd4=";
            })
          ];
          nativeBuildInputs = [ pkgs-unpatched.nix ];
          dontConfigure = true;
          dontBuild = true;
          dontCheck = true;
          installPhase = ''
            runHook preInstall

            cp -r . $out

            runHook postInstall
          '';
          dontFixup = true;
        };
        nixpkgs-patched = getFlake "${nixpkgs-patched-src}";
        pkgs = (import nixpkgs-patched { inherit system; config.allowUnfree = true; });
      in {
        name = hostname;
        value = nixpkgs-patched.lib.nixosSystem {
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
      }) hosts);
    };
}
