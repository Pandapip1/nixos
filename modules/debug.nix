{
  config,
  ...
}:

{
  # Provides debug symbols for troubleshooting purposes
  services.nixseparatedebuginfod2 = {
    enable = true;
    substituters = config.nix.settings.substituters;
  };
}
