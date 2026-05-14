{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  # GRUB, because I prefer GRUB to systemd-boot
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      efiSupport = true;
      memtest86.enable = true;
    };
  };

  # Kernel stuff
  boot.kernelParams = [ ];
  boot.initrd.availableKernelModules = [
    "ehci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Use disko for filesystem management
  imports = [ ./disko-config.nix ];
}
