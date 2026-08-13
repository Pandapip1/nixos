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
        # MUDHUTS_OUTPUT_SCALE=1.0 pins the output to 1x scale while the
        # fractional-scale-v1 work (mudhuts commit 87adb1c) is investigated
        # for a live-session regression (fuzzy rendering, only the
        # top-left of the panel visible) — remove once that's fixed.
        exec = "${lib.getExe' pkgs.coreutils "env"} RUST_LOG=debug MUDHUTS_OUTPUT_SCALE=1.0 ${lib.getExe pkgs.mudhuts} --tty";
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
