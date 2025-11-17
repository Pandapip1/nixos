{
  lib,
  config,
  ...
}:

{
  programs.thunderbird = {
    enable = lib.mkDefault (config.services.graphical-desktop.enable && !(config.optimizations.lean.enable));
  };
}
