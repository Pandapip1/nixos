{ config, lib, pkgs, modulesPath, ... }:

{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 16;
    };
    efi.canTouchEfiVariables = true;
  };

  defaults.workstation = true;


  # Zram
  zramSwap = {
    enable = true;
  };


  programs = {
    localsend.enable = true;
  };

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "firewire_ohci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" 
"nvme" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/369d6beb-b9b5-47c2-a4da-7014787b9fbd";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/58FE-67A7";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/d173a826-59c3-4093-a422-d24396f69e62"; }
    ];

  system.stateVersion = "25.11";
}
