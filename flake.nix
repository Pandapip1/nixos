{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-pr-308317.url = "github:Pandapip1/nixpkgs/init-cups-idprt";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    envision = {
      url = "gitlab:Scrumplex/envision/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    telescope = {
      url = "github:Pandapip1/telescope/nixgl";
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
      inputs.niri-unstable.follows = "niri";
      inputs.niri-stable.follows = "niri";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-pr-308317, flake-utils, ... }@inputs:
    let
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      pkgs-pr-308317 = import nixpkgs-pr-308317 { inherit system; config.allowUnfree = true; };
      system = "x86_64-linux";
      hostsDir = ./hosts;
      hosts = map (s: builtins.substring 0 (builtins.stringLength s - 4) s) (builtins.attrNames (builtins.readDir hostsDir));
    in {
      nixosConfigurations = builtins.listToAttrs (map (hostname: {
        name = hostname;
        value = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = inputs // {
            inherit system;
            hostname = hostname;
            pkgs = pkgs;
            pkgs-pr-308317 = pkgs-pr-308317;
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
