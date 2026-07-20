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
    exec > >(exec systemd-cat -t stardust-session) 2>&1
    set -x

    export XDG_CURRENT_DESKTOP=X-stardust-session

    # Make the session's environment visible to systemd --user
    systemctl --user import-environment XDG_SESSION_ID XDG_VTNR XDG_RUNTIME_DIR XDG_CURRENT_DESKTOP

    # Reach graphical-session.target indirectly via our own bound target,
    # since graphical-session.target itself refuses manual starts
    systemctl --user start stardust-session.target

    SOCK="''${XDG_RUNTIME_DIR}/monado_comp_ipc"
    for i in $(seq 1 50); do
      [ -S "$SOCK" ] && break
      sleep 0.1
    done

    systemctl --user start xdg-desktop-autostart.target

    exec ${lib.getExe pkgs.stardust-xr-server}
  '';
in
{
  services.displayManager.sessionPackages = [ stardustSession ];

  systemd.user.targets.stardust-session = {
    description = "Stardust XR compositor session";
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };

  environment.systemPackages = [
    (pkgs.makeDesktopItem {
      destination = "/etc/xdg/autostart";
      desktopName = "Stardust XR Flatland";
      name = "stardust-xr-flatland";
      extraConfig.OnlyShowIn = "X-stardust-session";
      exec = lib.getExe pkgs.stardust-xr-flatland;
    })
  ];
}
