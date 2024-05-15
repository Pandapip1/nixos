{
  description = "A NixOS configuration with per-hostname modifications";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-pr-308317.url = "github:Pandapip1/nixpkgs/init-cups-idprt";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-software-center = {
      url = "github:snowfallorg/nix-software-center";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-conf-editor = {
      url = "github:snowfallorg/nixos-conf-editor";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };

  outputs = { self, nixpkgs, nixpkgs-pr-308317, flake-utils, agenix, ... }@args:
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
          specialArgs = args // {
            inherit system;
            hostname = hostname;
            pkgs = pkgs;
            pkgs-pr-308317 = pkgs-pr-308317;
          };
          modules = [
            ./common.nix
            (hostsDir + "/${hostname}.nix")
            agenix.nixosModules.default
          ];
        };
      }) hosts);
    };
}
