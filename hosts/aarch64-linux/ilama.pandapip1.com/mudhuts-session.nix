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
        name = "mudhuts";
        comment = "mudhuts: a terminal-centric Wayland compositor";
        exec = "${lib.getExe' pkgs.coreutils "env"} RUST_LOG=debug ${lib.getExe pkgs.mudhuts} --tty";
        type = "Application";
        desktopName = "mudhuts";
      }).overrideAttrs (oldAttrs: {
        passthru = (oldAttrs.passthru or { }) // {
          providedSessions = [ "mudhuts" ];
        };
      })
    )
  ];
}
