{
  lib,
  pkgs,
  ...
}:

{
  services.displayManager.sessionPackages = [
    (
      (pkgs.makeDesktopItem {
        destination = "/share/wayland-sessions";
        name = "stardust-xr";
        comment = "TODO";
        exec = lib.getExe pkgs.stardust-xr-server;
        type = "Application";
        desktopName = "Stardust XR";
      }).overrideAttrs (oldAttrs: {
        passthru = (oldAttrs.passthru or {}) // {
          providedSessions = [ "stardust-xr" ];
        };
      })
    )
    (
      (pkgs.makeDesktopItem {
        destination = "/share/wayland-sessions";
        name = "kmscon";
        comment = "TODO";
        exec = lib.getExe pkgs.kmscon;
        type = "Application";
        desktopName = "kmscon";
      }).overrideAttrs (oldAttrs: {
        passthru = (oldAttrs.passthru or {}) // {
          providedSessions = [ "kmscon" ];
        };
      })
    )
  ];
}
