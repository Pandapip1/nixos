{
  lib,
  config,
  ...
}:

lib.mkIf config.services.graphical-desktop.enable {
  environment.systemPackages = with pkgs; [
    gimp
  ];
}
