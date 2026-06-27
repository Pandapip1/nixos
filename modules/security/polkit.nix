{
  lib,
  config,
  ...
}:

lib.mkIf (config.services.graphical-desktop.enable && !config.services.desktopManager.cosmic.enable)
  {
    # Use soteria as our polkit agent
    # Seemingly no tty-based polkit agents (sort of makes sense)
    # COSMIC has cosmic-osd, we'll use that
    security.soteria.enable = true;
  }
