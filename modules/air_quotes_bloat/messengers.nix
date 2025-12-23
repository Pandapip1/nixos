{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf (config.services.graphical-desktop.enable && !(config.optimizations.lean.enable)) {
  environment.systemPackages = with pkgs; [
    vesktop
    caprine
    slacky
    telegram-desktop
    element-desktop
    mattermost-desktop
  ];
}
