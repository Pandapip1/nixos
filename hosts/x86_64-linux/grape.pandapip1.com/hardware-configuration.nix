{
  nixos-hardware,
  ...
}:

{
  imports = [
    nixos-hardware.nixosModules.common.cpu.intel
  ];

  # This audio device is for the radio, forbid pipewire from touching it
  # monitor.alsa.rules = [
  #   {
  #     matches = [
  #       {
  #         device.name = "~alsa_card.pci-*"
  #       },
  #       {
  #         device.name = "alsa_card.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-00"
  #       }
  #     ]
  #     actions = {
  #       update-props = {
  #         device.disabled = true
  #       }
  #     }
  #   }
  # ]

  boot = {
    initrd = {
      availableKernelModules = [
        "uhci_hcd"
        "ehci_pci"
        "ahci"
        "firmware_ohci"
        "sd_mod"
        "sr_mod"
        "sdhci_pci"
      ];
      kernelModules = [];
    };
    kernelModules = [];
    extraModulePackages = [];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/76f1c9de-99a8-4145-9ca6-d7cabed7f419";
    fsType = "ext4";
  };

  swapDevices = [];
}
