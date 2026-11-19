{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf (!(config.optimizations.lean.enable)) {
  extraProfiles.singleton.packages = with pkgs; [
    empryo-tui
  ];
}
