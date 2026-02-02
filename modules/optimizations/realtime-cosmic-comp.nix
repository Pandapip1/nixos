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
          echo "Waiting for cosmic-comp..."
          while ! pgrep -x cosmic-comp >/dev/null; do
            sleep 0.05
          done

          PID=$(pgrep -x cosmic-comp | head -n1)
          echo "Promoting cosmic-comp (PID=$PID) to SCHED_RR"

          ${lib.getExe' pkgs.rtkit "rtkitctl"} \
            --pid=$PID \
            --rr \
            --priority=30
        '
      '';
    };
};
}
