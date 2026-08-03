{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf
  (
    config.services.graphical-desktop.enable
    && !(config.optimizations.lean.enable)
    && (pkgs.stdenv.hostPlatform.system == "x86_64-linux")
  )
  {
    extraProfiles.singleton.packages = with pkgs; [
      grayjay
    ];
  }
