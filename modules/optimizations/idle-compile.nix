{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.optimizations.idleCompile;

  sliceName = "compile";
  sliceUnit = "${sliceName}.slice";

  # Entry points for compile/link jobs. cgroup membership is inherited by
  # forked children (cc1/cc1plus/as/ld spawned by gcc, ninja's build
  # actions, etc.), so listing the driver/build-tool binaries is enough to
  # catch a whole build; the rest are listed too as a safety net for tools
  # invoked directly rather than as a child of one of these.
  compileProcessNames = [
    "gcc"
    "cc"
    "g++"
    "c++"
    "clang"
    "clang++"
    "cc1"
    "cc1plus"
    "cc1obj"
    "lto1"
    "lto-wrapper"
    "as"
    "ld"
    "ld.bfd"
    "ld.gold"
    "ld.lld"
    "mold"
    "rustc"
    "cargo"
    "make"
    "gmake"
    "ninja"
    "meson"
    "go"
    "javac"
    "mvn"
    "gradle"
    "ccache"
    "sccache"
  ];

  # The real qemu-user binaries that boot.binfmt.emulatedSystems registers
  # (see nixos/modules/system/boot/binfmt.nix). binfmt invokes a small
  # wrapper first, which execs into this binary; cgrulesengd reclassifies
  # the process on that exec, so no wrapping on our end is needed.
  qemuProcessNames = map (
    system: "qemu-${(lib.systems.elaborate { inherit system; }).qemuArch}"
  ) config.boot.binfmt.emulatedSystems;

  # Some packages (following the makeWrapper convention used e.g. by
  # cosmic-comp, see modules/optimizations/realtime-cosmic-comp.nix) move
  # the real binary aside and exec into it from a same-named wrapper
  # script, under either "<name>-wrapped" or ".<name>-wrapped". Match those
  # too so wrapped toolchains/emulators still land in the idle slice.
  withWrappedVariants = name: [
    name
    "${name}-wrapped"
    ".${name}-wrapped"
  ];

  processNames = lib.concatMap withWrappedVariants (compileProcessNames ++ qemuProcessNames);
in
{
  options.optimizations.idleCompile.enable =
    lib.mkEnableOption ''
      starving compile jobs and binfmt-emulated (qemu-user) processes of CPU
      whenever the system is otherwise busy, and making them the preferred
      target when systemd-oomd needs to kill something under memory
      pressure. Matching processes are moved into a cgroup slice with
      CPUWeight=idle, so they only get scheduled once every other process
      has had a chance to run
    ''
    // {
#      default = true;
    };

  config = lib.mkIf cfg.enable {
    systemd.slices.${sliceName} = {
      description = "Idle-priority CPU slice for compile jobs and emulated processes";
      sliceConfig = {
        CPUWeight = "idle";
        # No other slice on this system opts into systemd-oomd (see
        # systemd.oomd.enable{RootSlice,SystemSlice,UserSlices}), so this
        # makes compile.slice the only thing systemd-oomd will ever kill
        # from under memory pressure or swap thrashing.
        ManagedOOMSwap = "kill";
        ManagedOOMMemoryPressure = "kill";
      };
      wantedBy = [ "multi-user.target" ];
    };

    environment.etc."cgrules.conf".text = ''
      # Managed by NixOS (modules/optimizations/idle-compile.nix).
      # Routes compile-toolchain and binfmt-emulated (qemu-user) processes
      # into ${sliceUnit}, which only gets CPU time once every other cgroup
      # is idle.
      ${lib.concatMapStringsSep "\n" (name: "*:${name}\t*\t${sliceUnit}") processNames}
    '';

    systemd.services.cgrulesengd = {
      description = "cgroup rules engine daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ sliceUnit ];
      requires = [ sliceUnit ];
      serviceConfig = {
        ExecStart = "${lib.getExe' pkgs.libcgroup "cgrulesengd"} --nodaemon --syslog";
        Restart = "on-failure";
      };
    };
  };
}
