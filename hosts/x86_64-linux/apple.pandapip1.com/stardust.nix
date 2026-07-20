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

    systemctl --user import-environment XDG_SESSION_ID XDG_VTNR XDG_RUNTIME_DIR XDG_CURRENT_DESKTOP

    SOCK="''${XDG_RUNTIME_DIR}/monado_comp_ipc"
    for i in $(seq 1 50); do
      [ -S "$SOCK" ] && break
      sleep 0.1
    done

    # Starts stardust-xr-server.service + everything WantedBy it,
    # and blocks here until the whole session tears down
    exec systemctl --user start --wait stardust-session.target
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

  systemd.user.services.stardust-xr-server = {
    description = "Stardust XR server";
    partOf = [ "stardust-session.target" ];
    wantedBy = [ "stardust-session.target" ];
    serviceConfig = {
      ExecStart = lib.getExe pkgs.stardust-xr-server;
      Restart = "no";
    };
  };

  systemd.user.services.stardust-xr-flatland = {
    description = "Stardust XR Flatland (2D app panels)";
    partOf = [ "stardust-session.target" ];
    wantedBy = [ "stardust-session.target" ];
    after = [ "stardust-xr-server.service" ];
    serviceConfig = {
      ExecStart = lib.getExe pkgs.stardust-xr-flatland;
      Restart = "on-failure";
    };
  };

  systemd.user.services.stardust-hexagon-launcher = {
    description = "Stardust XR Hexagon Launcher";
    partOf = [ "stardust-session.target" ];
    wantedBy = [ "stardust-session.target" ];
    after = [ "stardust-xr-server.service" ];
    serviceConfig = {
      ExecStart = lib.getExe' pkgs.stardust-xr-protostar "hexagon_launcher";
      Restart = "on-failure";
    };
  };

  systemd.user.services.stardust-eclipse-simular = {
    description = "Stardust XR libinput input (eclipse | simular)";
    partOf = [ "stardust-session.target" ];
    wantedBy = [ "stardust-session.target" ];
    after = [ "stardust-xr-server.service" ];
    serviceConfig = {
      # eclipse reads raw libinput devices, no desktop window needed
      ExecStart = "${lib.getExe pkgs.bash} -c '${lib.getExe' pkgs.stardust-xr-non-spatial-input "eclipse"} | ${lib.getExe' pkgs.stardust-xr-non-spatial-input "simular"}'";
      Restart = "on-failure";
    };
  };

  systemd.user.services.stardust-atmosphere = {
    description = "Stardust XR atmosphere (3D environment/background)";
    partOf = [ "stardust-session.target" ];
    wantedBy = [ "stardust-session.target" ];
    after = [ "stardust-xr-server.service" ];
    serviceConfig = {
      ExecStartPre = [
        "${lib.getExe pkgs.stardust-xr-atmosphere} install ${pkgs.stardust-xr-atmosphere.src}/default_envs/the_grid"
        "${lib.getExe pkgs.stardust-xr-atmosphere} set-default the_grid"
      ];
      ExecStart = "${lib.getExe pkgs.stardust-xr-atmosphere} show";
      Restart = "on-failure";
    };
  };
}
