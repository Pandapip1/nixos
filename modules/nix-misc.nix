{ lib, config, pkgs, nixpkgs, ... }:

{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
    registry = {
      nixpkgs.to = {
        type = "path";
        path = pkgs.path;
        narHash = builtins.readFile
            (pkgs.runCommandLocal "get-nixpkgs-hash"
              { nativeBuildInputs = [ pkgs.nix ]; }
              "nix-hash --type sha256 --sri ${pkgs.path} > $out");
      };
      # TODO: Add nixos-config for nixos-option command
    };
    nixPath = lib.mkForce [ "nixpkgs=${nixpkgs.outPath}" ];
    channel.enable = false;
    package = pkgs.nixVersions.latest;
  };

  nixpkgs.config.warnUndeclaredOptions = true;
}
