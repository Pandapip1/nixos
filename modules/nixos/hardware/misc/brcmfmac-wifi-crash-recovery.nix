# On this machine's BCM4387 (Wi-Fi/BT combo chip), brcmfmac's PCIe firmware
# bring-up intermittently crashes on cold boot -- the exact crash signature
# (THREADX TRAP address, stack contents) varies between boots, but the
# outcome is always the same: brcmf_pcie_setup()'s failure path logs
# "Dongle setup failed", calls brcmf_fw_crashed(), then device_release_driver()
# (drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c), unbinding the
# driver from the PCI device. The module stays loaded but no wifi interface
# ever appears, requiring `modprobe -r brcmfmac_wcc brcmfmac && modprobe
# brcmfmac` to recover -- which almost always succeeds on the second try.
#
# This hasn't been root-caused upstream (not the already-fixed BCM4387
# AXI-reset issue from released-by-driver-instead-of-firmware D11 core resets
# -- that fix is already in this kernel, see brcmf_chip_cr4_set_passive in
# chip.c). 0004-wireless-brcmfmac-bounded-firmware-retry.patch now retries
# the firmware bring-up in-kernel (3 attempts, each from a hardware reset)
# before device_release_driver() is ever called, so this service should
# fire far less often than before -- but it's bounded, not guaranteed, and
# it only resets the chip, never rebuilding the driver's own software-side
# state the way a full module reload does. This stays as the last-resort
# backstop: a full `modprobe -r && modprobe` reload (a different, more
# thorough remedy than the in-kernel retry) for the residual case where the
# kernel still gives up.
#
# Each invocation does one settle-wait-then-check-then-maybe-reload pass,
# and relies on systemd's own Restart=/StartLimit* machinery for the
# "try again, but not forever" loop instead of hand-rolling one in the
# script -- exit 0 (bound, or nothing to do) is terminal; exit 1 (not
# bound even after a reload attempt) triggers a restart, up to
# startLimitBurst times within startLimitIntervalSec, after which systemd
# gives up and leaves the unit failed rather than retrying indefinitely.
{
  lib,
  pkgs,
  config,
  ...
}:

lib.mkIf config.hardware.asahi.enable {
  systemd.services.brcmfmac-crash-recovery = {
    description = "Recover BCM4387 wifi if brcmfmac's firmware crashed on probe";
    wantedBy = [ "multi-user.target" ];
    before = [
      "network-pre.target"
      "NetworkManager.service"
      "wpa_supplicant.service"
    ];
    startLimitIntervalSec = 600;
    startLimitBurst = 5;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = lib.getExe (pkgs.writeShellApplication {
        name = "brcmfmac-crash-recovery";
        runtimeInputs = [ pkgs.kmod ];
        text = ''
          bound() {
            find /sys/bus/pci/drivers/brcmfmac -maxdepth 1 -name '[0-9a-f][0-9a-f][0-9a-f][0-9a-f]:*' \
              2>/dev/null | grep -q .
          }

          # brcmfmac is loaded on-demand by udev when it matches the PCI
          # device; give that a little while to happen before deciding
          # there's nothing to recover.
          for _ in $(seq 1 20); do
            [ -d /sys/bus/pci/drivers/brcmfmac ] && break
            sleep 0.5
          done
          if [ ! -d /sys/bus/pci/drivers/brcmfmac ]; then
            exit 0
          fi

          # The in-kernel patch now retries firmware bring-up up to 3 times
          # itself (each a hardware reset + firmware refetch) before giving
          # up, which can take longer than the single attempt this timing
          # was originally tuned for. Give it comfortable room to exhaust
          # its own retries before we judge "not bound" and reload out from
          # under it.
          sleep 30
          bound && exit 0

          echo "brcmfmac has no bound device after the kernel's own retries, reloading the module" \
            | systemd-cat -p warning -t brcmfmac-crash-recovery
          modprobe -r brcmfmac_wcc brcmfmac || true
          modprobe brcmfmac

          # Don't wait around for this reload's own outcome here -- exit 1
          # and let the next restart's settle-wait-then-check do that.
          exit 1
        '';
      });
    };
  };
}
