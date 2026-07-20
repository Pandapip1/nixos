{
  lib,
  pkgs,
  ...
}:

let
  stardustSession =
    (pkgs.makeDesktopItem {
      destination = "/share/wayland-sessions";
      desktopName = "Stardust XR";
      name = "stardust-session";
      comment = "KMS/DRM text console session";
      exec = lib.getExe stardustSessionScript;
      type = "Application";
    }).overrideAttrs
      (oldAttrs: {
        passthru = (oldAttrs.passthru or { }) // {
          providedSessions = [ "stardust-session" ];
        };
      });

  stardustSessionScript = pkgs.writeShellScriptBin "start-stardust-session" ''
    # start-stardust-session

    export XDG_CURRENT_DESKTOP=stardust-session

    # Make the session's environment visible to systemd --user
    systemctl --user import-environment XDG_SESSION_ID XDG_VTNR XDG_RUNTIME_DIR XDG_CURRENT_DESKTOP

    # Actually reach graphical-session.target, which monado.service depends on
    systemctl --user start graphical-session.target

    export XR_RUNTIME_JSON=/etc/xdg/openxr/1/openxr_monado.json

    # monado.service should now be starting (or already started, if pam_systemd
    # reached the target on its own — worth checking with `loginctl show-session`)
    SOCK="''${XDG_RUNTIME_DIR}/monado_comp_ipc"
    for i in $(seq 1 50); do
      [ -S "$SOCK" ] && break
      sleep 0.1
    done

    # Run XDG autostart entries via systemd-xdg-autostart-generator-created units
    systemctl --user start xdg-desktop-autostart.target

    exec ${lib.getExe pkgs.stardust-xr-server} --some-flag
  '';
in
{
  services.displayManager.sessionPackages = [ stardustSession ];
  xdg.autostart.install = [
    (pkgs.makeDesktopItem {
      name = "Flatland";
      destination = "/etc/xdg/autostart";
      extraConfig.OnlyShowIn = "stardust-session";
    })
  ];
}
