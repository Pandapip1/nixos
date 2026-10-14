{ config, lib, ... }:

let
  cfg = config.optimizations.criticalRealtime;

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
  options.optimizations.criticalRealtime.enable =
    lib.mkEnableOption ''
      real-time scheduling for daemons everything else transitively depends
      on -- D-Bus, session/seat management (logind), DNS (unbound), the
      real-time priority grantor itself (rtkit), the OOM killer
      (systemd-oomd), audio (pipewire/wireplumber), input remapping
      (inputplumber), and speaker protection (speakersafetyd) -- so they
      always preempt ordinary programs instead of just sharing the CPU
      fairly with them. If one of these stalls, whatever depends on it
      stalls too, so it needs to keep running even when the system is
      otherwise saturated
    ''
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    systemd.services = lib.mkMerge [
      # Practically everything talks over D-Bus (session/seat management,
      # policykit, most desktop portals); if it can't get scheduled,
      # unrelated things across the whole system start timing out.
      (lib.mkIf (config.services.dbus.implementation == "broker") (
        lib.listToAttrs [ (rt "dbus-broker" 70) ]
      ))
      (lib.mkIf (config.services.dbus.implementation != "broker") (lib.listToAttrs [ (rt "dbus" 70) ]))

      # Seat/session management: VT switching, lid/power button, and
      # handing DRM master to the compositor in the first place. Always
      # present (core systemd), no enable option to gate on.
      (lib.listToAttrs [ (rt "systemd-logind" 75) ])

      # If this stalls, name resolution stalls for basically everything
      # network-facing -- same "everything downstream breaks" tier as
      # D-Bus.
      (lib.mkIf config.services.unbound.enable (lib.listToAttrs [ (rt "unbound" 65) ]))

      # rtkit is what *grants* other processes real-time priority on
      # request (the RealtimeKit1 D-Bus API); if it's itself starved,
      # whatever asks it for RT priority under load doesn't get it when it
      # matters most.
      (lib.mkIf config.security.rtkit.enable (lib.listToAttrs [ (rt "rtkit-daemon" 91) ]))

      # Needs to be able to react before the kernel's own OOM killer picks
      # something at random -- that's the entire point of running it.
      (lib.mkIf config.systemd.oomd.enable (lib.listToAttrs [ (rt "systemd-oomd" 92) ]))

      (lib.mkIf config.services.pipewire.enable (
        lib.listToAttrs (
          [ (rt "pipewire" 90) ]
          ++ lib.optional config.services.pipewire.pulse.enable (rt "pipewire-pulse" 85)
          ++ lib.optional config.services.pipewire.wireplumber.enable (rt "wireplumber" 80)
        )
      ))

      # Starved input remapping shows up as felt input lag/dropped events,
      # same category of user-visible harm as an audio glitch.
      (lib.mkIf config.services.inputplumber.enable (lib.listToAttrs [ (rt "inputplumber" 78) ]))

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
