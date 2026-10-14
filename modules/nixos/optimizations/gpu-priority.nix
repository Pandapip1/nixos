{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.optimizations.gpuPriority;

  # Every open DRM file shows up as a row in this debugfs table, one per
  # card. The kernel's own "master" column (drm_is_current_master(), see
  # drivers/gpu/drm/drm_auth.c) is 'y' for both the actual DRM master (the
  # compositor/greeter currently driving the display) *and* any active
  # lessee (drivers/gpu/drm/drm_lease.c: a lease is implemented as its own
  # scoped drm_master, and drm_is_current_master() walks the lessor chain
  # back to the device's real master) -- so this one column covers exactly
  # "holds DRM master or a DRM lease" with no extra work to special-case
  # leases.
  #
  # Rather than moving these processes into a dedicated cgroup (which risks
  # orphaning/GC'ing whatever transient scope they came from once it's
  # emptied), this just bumps CPUWeight on whichever unit already contains
  # them, via `systemctl set-property --runtime`, and resets it once they
  # stop holding master/a lease. That leaves the real-time scheduled
  # critical daemons (see optimizations.criticalRealtime and
  # optimizations.idleCompile) untouched and still strictly higher priority
  # -- cgroup CPUWeight only governs the SCHED_OTHER class RT tasks always
  # preempt, regardless of weight.
  script = pkgs.writeShellScript "gpu-priority-monitor" ''
    set -uo pipefail
    shopt -s nullglob

    declare -A boosted=()

    while true; do
      declare -A current=()

      for clients in /sys/kernel/debug/dri/*/clients; do
        [ -r "$clients" ] || continue
        while read -r _cmd pid _dev master _rest; do
          [ "$master" = "y" ] || continue
          unit=$(${lib.getExe' pkgs.systemd "systemctl"} whoami "$pid" 2>/dev/null) || continue
          [ -n "$unit" ] || continue
          current["$unit"]=1
        done < <(tail -n +2 "$clients" 2>/dev/null)
      done

      for unit in "''${!current[@]}"; do
        if [ -z "''${boosted[$unit]:-}" ]; then
          ${lib.getExe' pkgs.systemd "systemctl"} set-property --runtime "$unit" CPUWeight=10000 2>/dev/null || true
          boosted["$unit"]=1
        fi
      done

      for unit in "''${!boosted[@]}"; do
        if [ -z "''${current[$unit]:-}" ]; then
          ${lib.getExe' pkgs.systemd "systemctl"} set-property --runtime "$unit" CPUWeight= 2>/dev/null || true
          unset "boosted[$unit]"
        fi
      done

      sleep 2
    done
  '';
in
{
  options.optimizations.gpuPriority.enable =
    lib.mkEnableOption ''
      boosting the CPU priority of whatever currently holds DRM master or a
      DRM lease (the active compositor/greeter, and anything it's leased a
      display to, e.g. a VR runtime) over everything else, short of the
      real-time scheduled critical daemons (speakersafetyd,
      systemd-oomd) which always win regardless
    ''
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    systemd.services.gpu-priority-monitor = {
      description = "Boost CPU priority of DRM master/lease holders";
      wantedBy = [ "multi-user.target" ];
      # Skip entirely on hosts with no DRM devices at boot (headless
      # servers); doesn't re-evaluate if a GPU driver loads later, but
      # every real target for this is a desktop/laptop with a GPU present
      # from early boot.
      unitConfig.ConditionPathIsDirectory = "/sys/kernel/debug/dri";
      serviceConfig = {
        ExecStart = script;
        Restart = "always";
        RestartSec = 1;
        # This is itself part of the critical path: if it gets starved, it
        # can't do its job of un-starving whatever needs it. Its own CPU
        # use is negligible (a few-second poll loop), so this is safe to
        # set unconditionally rather than gating on optimizations.criticalRealtime.
        CPUSchedulingPolicy = "rr";
        CPUSchedulingPriority = 50;
      };
    };
  };
}
