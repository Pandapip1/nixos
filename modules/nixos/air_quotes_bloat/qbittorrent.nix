{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf (config.services.graphical-desktop.enable && !(config.optimizations.lean.enable)) {
  extraProfiles.singleton.packages = with pkgs; [
    qbittorrent
  ];
}
