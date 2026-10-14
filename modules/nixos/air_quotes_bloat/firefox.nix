{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf config.services.graphical-desktop.enable {
  extraProfiles.singleton.packages = [
    (pkgs.wrapFirefox pkgs.firefox-unwrapped {
      extraPrefs = lib.concatStringsSep "\n" (
        lib.mapAttrsToList
          (
            name: value:
            ''lockPref("${name}", ${
              if lib.isBool value then
                (if value then "true" else "false")
              else if lib.isInt value then
                toString value
              else
                ''"${value}"''
            });''
          )
          {
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
          }
      );
    })
  ];
}
