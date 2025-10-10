{
  config,
  ...
}:

{
  # TODO: Work on pinentry-cosmic
  programs.gnupg.agent.pinentryPackage = if config.services.graphical-desktop.enable then pkgs.pinentry-qt else pkgs.pinentry-bemenu;
}
