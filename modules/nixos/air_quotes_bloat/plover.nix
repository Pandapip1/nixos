{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf (config.services.graphical-desktop.enable && !(config.optimizations.lean.enable)) {
  extraProfiles.singleton.packages = with pkgs; [
    (plover_5.overridePythonAttrs (old: {
      dependencies =
        old.dependencies
        ++ (with python3Packages; [
          plover-lapwing-aio
          plover-plugin-fcitx5-keyboardcontrol
        ]);
      catchConflicts = false;
    }))
  ];
}
