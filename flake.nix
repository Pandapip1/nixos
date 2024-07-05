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
        nixpkgs-patched-source = pkgs-unpatched.stdenvNoCC.mkDerivation {
          name = "nixpkgs-patched-source";
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
              name = "init-stardust-xr-server.patch";
              url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/324375.patch";
              hash = "sha256-6Se3ZKvb7N/Z1Mo4Bx9B868PlTqVXJo4koL0hXE0u/E=";
            })
            (fetchpatch {
              name = "init-stardust-xr-flatland.patch";
              url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/324395.patch";
              hash = "sha256-VtIC40bHzlx9iYktttd7nsi3WKs3h00u3OalSTguNbc=";
            })
            (fetchpatch {
              name = "init-stardust-xr-kiara.patch";
              url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/324404.patch";
              hash = "sha256-qAIt5YbJPxewM3wnbTxo24LgmewtQ8MDpKDuzdYJdls=";
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
        nixpkgs-patched = getFlake "${nixpkgs-patched-source}";
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
