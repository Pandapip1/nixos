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
        exec = "${pkgs.writeShellScript "mudhuts-session" ''
          export RUST_LOG=debug
          exec ${lib.getExe pkgs.mudhuts} --tty > /tmp/mudhuts-greeter.log 2>&1
        ''}";
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
