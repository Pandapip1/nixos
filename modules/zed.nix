{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zed;

in {
  options = {
    programs.zed = {
      enable = mkEnableOption "zed editor";
      package = mkPackageOption pkgs "zed-editor";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];
  };
}
