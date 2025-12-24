{ lib, config, pkgs, self, nixpkgs, nur, ... }:

{
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    channel.enable = false;
    package = pkgs.nixVersions.latest;
    nixPath = lib.mkForce [
      "nixpkgs=flake:nixpkgs"
      "nur=flake:nur"
      # `nix-instantiate --eval -E '(import <config>)'` will get the config for the current machine
      "config=${pkgs.writeText "configuration.nix" "(builtins.getFlake (toString ${self.outPath})).nixosConfigurations.${config.networking.hostName}.config"}"
    ];
    registry = let
      mkRegistryEntry = name: path: {
        ${name}.to = {
          type = "path";
          inherit path;
          narHash = builtins.readFile (
            pkgs.runCommandLocal "get-${name}-hash" {
              nativeBuildInputs = [ pkgs.nix ];
            } "nix-hash --type sha256 --sri ${path} > $out"
          );
        };
      };
    in 
      mkRegistryEntry "nixpkgs" pkgs.path //
      mkRegistryEntry "nur" nur.outPath;
  };

  nixpkgs = {
    flake = {
      source = nixpkgs.outPath;
      setFlakeRegistry = false; # We do this ourselves
      setNixPath = false; # Again, we do this ourselves
    };
    config.warnUndeclaredOptions = true;
  };
}
