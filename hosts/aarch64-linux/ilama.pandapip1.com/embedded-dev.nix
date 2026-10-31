{
  ...
}:

# Embedded development (owo-open-fw): SEGGER J-Link probes, and the kernel
# devices QEMU passes through to emulated hardware (an emulated J-Link on a
# dummy_hcd UDC via raw-gadget, an emulated Bluetooth controller via vhci).
{
  boot.kernelModules = [
    "dummy_hcd"
    "raw_gadget"
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="1366", GROUP="plugdev", MODE="0660"
    KERNEL=="raw-gadget", GROUP="plugdev", MODE="0660"
    KERNEL=="vhci", GROUP="plugdev", MODE="0660"
  '';
}
