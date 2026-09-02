{ config, lib, ... }:

let
  cfg = config.optimizations.realtimeAudio;

  # Real-time (SCHED_RR) scheduling always preempts ordinary SCHED_OTHER
  # work, cgroup weights notwithstanding -- cgroup v2's cpu controller only
  # governs the SCHED_OTHER class, so this is the actual opposite number to
  # optimizations.idleCompile's CPUWeight=idle, not just a high CPUWeight.
  rt =
    name: priority:
    lib.nameValuePair name {
      serviceConfig = {
        CPUSchedulingPolicy = "rr";
        CPUSchedulingPriority = priority;
      };
    };
in
{
  options.optimizations.realtimeAudio.enable =
    lib.mkEnableOption ''
      real-time scheduling for latency- and safety-critical audio daemons
      (pipewire, wireplumber, speakersafetyd), so they always preempt
      ordinary programs instead of just sharing the CPU fairly with them
    ''
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    systemd.services = lib.mkMerge [
      (lib.mkIf config.services.pipewire.enable (
        lib.listToAttrs (
          [ (rt "pipewire" 90) ]
          ++ lib.optional config.services.pipewire.pulse.enable (rt "pipewire-pulse" 85)
          ++ lib.optional config.services.pipewire.wireplumber.enable (rt "wireplumber" 80)
        )
      ))
      # speakersafetyd (from nixos-apple-silicon) only clamps its own CPU
      # frequency floor/ceiling (uclamp); unlike pipewire it never elevates
      # its own scheduling policy despite holding CAP_SYS_NICE, so it needs
      # this override to actually get priority over other work -- which
      # matters, since its entire job is reacting fast enough to protect
      # the speakers.
      (lib.mkIf (config.hardware.asahi.enable && config.hardware.asahi.setupAsahiSound) (
        lib.listToAttrs [ (rt "speakersafetyd" 95) ]
      ))
    ];
  };
}
