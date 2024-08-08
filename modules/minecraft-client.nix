{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.minecraft-client;

in {
  options = {
    programs.minecraft-client = {
      enable = mkEnableOption "the official Minecraft™ client";

      package = mkPackageOption pkgs "minecraft" { };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
