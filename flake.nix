{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    getFlake.url = "github:ursi/get-flake";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vector = {
      url = "github:3webs-org/vector";
      inputs.nixpkgs.follows = "nixpkgs";
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
            (fetchpatch {
              name = "init-cups-idprt.patch";
              url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/308317.patch";
              hash = "sha256-0kZDccC4WaKL+y3QEypQjeRx3AO1mE2wZqPyN8b6bVE=";
            })
            (fetchpatch {
              name = "init-envision.patch";
              url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/321015.patch";
              hash = "sha256-iR8QTux5nN6TgeU/ishrNXG64beVqwRDoy+3AnMwB3U=";
            })
            (fetchpatch {
              name = "init-stardust-xr-server.patch";
              url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/324375.patch";
              hash = "sha256-BOLn7YhYo3qd4Wlm21RVqvwHabHMbFP6QH82fP+1lao=";
            })
            (fetchpatch {
              name = "init-stardust-xr-flatland.patch";
              url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/324395.patch";
              hash = "sha256-xkF815z5r38jTuUtsohq+IKt5cdu6xPxDEsMx3Rz1Hs=";
            })
            (fetchpatch {
              name = "init-stardust-xr-kiara.patch";
              url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/324404.patch";
              hash = "sha256-z4aBQYtuE9VeNZy4+BtoZW1boFBCH+d3AXKlre9bCOE=";
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
