{
  lib,
  config,
  ...
}:

{
  programs.firefox = {
    enable = lib.mkDefault config.services.graphical-desktop.enable;
    preferences = {
      # Enable theming
      "widget.gtk.libadwaita-colors.enabled" = false;

      # Switch default search engine to DDG
      "browser.search.defaultenginename" = "DuckDuckGo";
      "browser.search.defaulturl" = "https://duckduckgo.com/?q=";

      # Disable FF Password manager (I use KeePassXC)
      "signon.rememberSignons" = false;
      "signon.prefillForms" = false;
      "browser.formfill.enable" = false;

      # We're on NixOS, firefox can't update itself
      "update_notifications.enabled" = false;
    };
  };
}
