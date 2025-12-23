{ lib, config, pkgs, nixpkgs, ... }:

{
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
    channel.enable = false;
    package = pkgs.nixVersions.latest;
  };

  nixpkgs = {
    flake = {
      source = nixpkgs.outPath;
      setFlakeRegistry = true;
      setNixPath = true;
    };
    config.warnUndeclaredOptions = true;
  };
}
