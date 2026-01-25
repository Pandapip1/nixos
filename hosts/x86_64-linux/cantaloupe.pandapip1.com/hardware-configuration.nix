{
  # GRUB, because I prefer GRUB to systemd-boot
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      efiSupport = true;
      devices = lib.mkForce [ "/dev/disk/by-id/nvme-Samsung_SSD_990_EVO_Plus_1TB_S7U5NJ0Y601088H" ];
      memtest86.enable = true;
    };
  };

  # Kernel stuff
  boot.kernelParams = [ ];
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Use disko for filesystem management
  imports = [ ./disko-config.nix ];

  # Hardware
  hardware.amdgpu.opencl.enable = true;
  nixpkgs.config.rocmSupport = true;
}
