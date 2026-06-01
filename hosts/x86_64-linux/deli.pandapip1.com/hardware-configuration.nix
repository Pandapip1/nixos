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
    efi.grub = {
      enable = true;
      efiSupport = true;
      devices = lib.mkForce [ "/dev/disk/by-id/ata-PNY_CS900_250GB_SSD_PNY25122503210102203" ];
      memtest86.enable = true;
      efiInstallAsRemovable = true;
    };
  };

  # Kernel stuff
  boot.kernelParams = [ ];
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "usbhid"
    "uas"
    "ums_realtek"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  services.xserver.videoDrivers = [ "nvidia" ]; # Misnomer, still need this for DRM-based systems like wayland
  hardware.nvidia.branch = "legacy_580";
  hardware.nvidia.open = false; # Unsupported card

  # Use disko for filesystem management
  imports = [ ./disko-config.nix ];
}
