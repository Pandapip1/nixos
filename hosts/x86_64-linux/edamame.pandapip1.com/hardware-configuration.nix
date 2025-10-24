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
      efiInstallAsRemovable = true;
      devices = lib.mkForce [ "/dev/disk/by-id/ata-P3-256_9X50427070023" ];
      memtest86.enable = true;
    };
  };

  # Kernel stuff
  boot.initrd.availableKernelModules = [
    "ahci"
    "ohci_pci"
    "ehci_pci"
    "pata_atiixp"
    "mpt3sas"
    "usbhid"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Use disko for filesystem management
  imports = [ ./disko-config.nix ];
}
