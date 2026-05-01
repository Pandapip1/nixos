{
  lib,
  config,
  pkgs,
  ...
}:

{
  programs.chromium = {
    enable = lib.mkDefault config.services.graphical-desktop.enable;
  };
  environment.systemPackages = with pkgs; [
    ungoogled-chromium
  ];
}
