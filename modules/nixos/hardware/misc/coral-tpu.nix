{
  # Was broken on 7.1.x: gasket_mm_unmap_region() called zap_vma_ptes(),
  # which mainline renamed to zap_special_vma_range() in Linux 7.1. Fixed by
  # ../../patches/gasket/gasket-patches.nix.
  hardware.coral = {
    usb.enable = true;
    pcie.enable = true;
  };
}
