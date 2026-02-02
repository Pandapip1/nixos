{
  lib,
  pkgs,
  ...
}:

{
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
          while ! pgrep -x $BIN_NAME >/dev/null; do
            sleep 0.05
          done

          PID=$(pgrep -x $BIN_NAME | head -n1)
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
