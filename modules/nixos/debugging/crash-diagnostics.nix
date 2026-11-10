{
  config,
  lib,
  pkgs,
  ...
}:

let
  isAsahi = config.hardware.asahi.enable or false;
  isDeviceTree = isAsahi || config.hardware.deviceTree.name != null;
  # Asahi's U-Boot EFI has no runtime variable services, so efi_pstore
  # never registers there even though canTouchEfiVariables is set.
  isEfi = !isDeviceTree && config.boot.loader.efi.canTouchEfiVariables;

  # Physical RAM for ramoops, reserved through the devicetree so neither
  # the bootloader's EFI map nor Linux hands it out. Base + 2 GiB keeps it
  # inside DRAM on the smallest machines of each platform and clear of the
  # bootloaders' load addresses. Whether the contents survive a watchdog
  # reset is untested on both platforms.
  ramoopsBase = if isAsahi then "0x00000100 0x80000000" else "0x00000000 0x80000000";
  ramoopsOverlay = {
    name = "ramoops";
    dtsText = ''
      /dts-v1/;
      /plugin/;
      / {
        compatible = "${if isAsahi then "apple,arm-platform" else "rockchip,rk3588"}";
        fragment@0 {
          target-path = "/";
          __overlay__ {
            reserved-memory {
              #address-cells = <2>;
              #size-cells = <2>;
              ranges;
              ramoops@0 {
                compatible = "ramoops";
                reg = <${ramoopsBase} 0x0 0x200000>;
                record-size = <0x40000>;
                console-size = <0x80000>;
                pmsg-size = <0x40000>;
                ecc-size = <16>;
              };
            };
          };
        };
      };
    '';
  };

  # nixos-apple-silicon builds m1n1/boot.bin from the kernel's own DTBs,
  # bypassing hardware.deviceTree; rebuild it the same way from the
  # overlaid ones (apple-silicon-support/modules/boot-m1n1).
  asahiBootFiles =
    let
      bootM1n1 = pkgs.m1n1.override (
        lib.optionalAttrs (config.boot.m1n1CustomLogo != null) {
          customLogo = config.boot.m1n1CustomLogo;
        }
      );
      bootUBoot = config.hardware.asahi.pkgs.uboot-asahi.override { m1n1 = bootM1n1; };
    in
    {
      "m1n1/boot.bin" = pkgs.runCommand "boot.bin" { } ''
        cat ${bootM1n1}/lib/m1n1/m1n1.bin \
            ${config.hardware.deviceTree.package}/apple/*.dtb \
            ${bootUBoot}/u-boot-nodtb.bin.gz \
            > $out
        if [ -n "${config.boot.m1n1ExtraOptions}" ]; then
          echo '${config.boot.m1n1ExtraOptions}' >> $out
        fi
      '';
    };
in
lib.mkMerge [
  {
    # Hard hangs left no trace: the journal stopped mid-stream with no
    # panic. Panic instead, so pstore and drm_panic get a chance.
    boot.kernelParams = [
      "softlockup_panic=1"
      "hardlockup_panic=1"
      "nmi_watchdog=1"
      "hung_task_panic=1"
    ];

    # Keep the seconds before a hang on disk.
    services.journald.settings.Journal.SyncIntervalSec = lib.mkDefault "1s";

    # Full-screen emergency messages, in the initrd and the running system.
    boot.initrd.systemd.services.systemd-bsod.wantedBy = [ "initrd.target" ];

    systemd.additionalUpstreamSystemUnits = [ "systemd-bsod.service" ];
    systemd.services.systemd-bsod.wantedBy = [ "sysinit.target" ];

    # Archive pstore records to /var/lib/systemd/pstore and free the backend
    # (NixOS already ships the unit).
    systemd.services.systemd-pstore.wantedBy = [ "sysinit.target" ];
  }

  (lib.mkIf isEfi {
    boot.kernelParams = [ "efi_pstore.pstore_disable=0" ];
  })

  (lib.mkIf isDeviceTree {
    hardware.deviceTree.overlays = [ ramoopsOverlay ];
    boot.kernelModules = [ "ramoops" ];
  })

  (lib.mkIf isAsahi {
    boot.loader.systemd-boot.extraFiles = lib.mkForce asahiBootFiles;
    boot.loader.grub.extraFiles = lib.mkForce asahiBootFiles;
    boot.loader.limine.additionalFiles = lib.mkForce asahiBootFiles;
    system.build.m1n1 = lib.mkForce asahiBootFiles."m1n1/boot.bin";
  })
]
