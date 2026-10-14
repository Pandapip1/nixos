{
  config,
  lib,
  nur,
  nixpkgs,
  pkgs,
  self,
  ...
}:

let
  configurationSet =
    if config.moduleClass == "nixos" then "nixosConfigurations" else "darwinConfigurations";
  mkRegistryEntry = name: path: {
    ${name}.to = {
      type = "path";
      inherit path;
      narHash = builtins.readFile (
        pkgs.buildPackages.runCommandLocal "get-${name}-hash" { }
          "${lib.getExe' pkgs.buildPackages.nix "nix-hash"} --type sha256 --sri ${path} > $out"
      );
    };
  };
in
{
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    channel.enable = false;
    package = pkgs.nixVersions.latest;
    nixPath = lib.mkForce [
      "nixpkgs=flake:nixpkgs"
      "nur=flake:nur"
      # `nix-instantiate --eval -E '(import <config>)'` returns this machine's config.
      "config=${pkgs.writeText "configuration.nix" ''
        (builtins.getFlake (toString ${self.outPath})).${configurationSet}.${config.networking.hostName}.config
      ''}"
    ];
  }
  // lib.optionalAttrs (config.moduleClass == "nixos") {
    # nix-darwin's registry renderer calls builtins.storePath, which is unavailable
    # during pure flake evaluation. Its flake registry remains available instead.
    registry = mkRegistryEntry "nixpkgs" pkgs.path // mkRegistryEntry "nur" nur.outPath;
  };

  nixpkgs = {
    flake = {
      source = nixpkgs.outPath;
      setFlakeRegistry = false;
      setNixPath = false;
    };
    config.warnUndeclaredOptions = true;
  };
}
