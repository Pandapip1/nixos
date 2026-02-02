{
  lib,
  pkgs,
  config,
  ...
}:

lib.mkIf config.services.desktopManager.cosmic.enable {
  systemd.user.services.cosmic-comp-rt = {
    description = "Promote cosmic-comp to SCHED_RR via rtkit";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${lib.getExe pkgs.bash} -lc '
          BIN_NAME=".cosmic-comp-wrapped"
          echo "Waiting for $BIN_NAME..."
          while ! pgrep -x "$BIN_NAME" >/dev/null; do
            sleep 1
          done

          PID=$(pgrep -n -x "$BIN_NAME")

          if chrt -p "$PID" 2>/dev/null | grep -q 'scheduling policy: SCHED_RR'; then
            echo "$BIN_NAME already SCHED_RR; done."
            exit 0
          fi

          echo "Promoting $BIN_NAME (PID=$PID) to SCHED_RR"

          ${lib.getExe' pkgs.rtkit "rtkitctl"} \
            --pid=$PID \
            --rr \
            --priority=15
        '
      '';
    };
  };
}
