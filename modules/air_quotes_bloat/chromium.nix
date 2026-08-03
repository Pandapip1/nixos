{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf (config.services.graphical-desktop.enable && !(config.optimizations.lean.enable)) {
  programs.chromium = {
    enable = lib.mkDefault true;
  };
  environment.systemPackages = with pkgs; [
    ungoogled-chromium
  ];
}
