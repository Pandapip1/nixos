{
  config,
  pkgs,
  ...
}:

{
  programs.gnupg.agent.pinentryPackage = if config.services.graphical-desktop.enable then pkgs.cosmic-ext-pinentry else pkgs.pinentry-bemenu;
}
