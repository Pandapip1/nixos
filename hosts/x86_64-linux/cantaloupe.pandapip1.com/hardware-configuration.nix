{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 16;
    };
    efi.canTouchEfiVariables = true;
  };

  # Hardware
  hardware.amdgpu.opencl.enable = true;
  nixpkgs.config.rocmSupport = true;

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "firewire_ohci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" 
"nvme" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems = {
    "/" = {
      fsType = "ext4";
      device = "/dev/disk/by-partlabel/root";
    };
    "/boot" = {
      fsType = "vfat";
      device = "/dev/disk/by-partlabel/EFI";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";
    }
  ];
}
