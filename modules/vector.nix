{ system, vector, config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.vector;

in {
  options = {
    programs.vector = {
      enable = mkEnableOption "Vector browser";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      vector.packages.${system}.default
    ];
  };
}
