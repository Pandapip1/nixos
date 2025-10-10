{
  lib,
  config,
  ...
}:

lib.mkIf config.services.graphical-desktop.enable {
  environment.systemPackages = with pkgs; [
    adwaita-icon-theme-legacy
  ];
}
