{
  lib,
  config,
  ...
}:

lib.mkIf config.services.graphical-desktop.enable {
  # Use soteria as our polkit agent
  # Seemingly no tty-based polkit agents (sort of makes sense)
  security.soteria.enable = true;
}
