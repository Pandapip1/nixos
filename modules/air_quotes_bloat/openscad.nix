{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf config.services.graphical-desktop.enable {
  environment.systemPackages = with pkgs; [
    openscad-unstable
  ];
}
