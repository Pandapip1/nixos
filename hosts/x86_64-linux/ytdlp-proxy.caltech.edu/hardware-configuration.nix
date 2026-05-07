{
  nixos-hardware,
  ...
}:

{
  imports = [
    nixos-hardware.nixosModules.common-cpu-intel
    nixos-hardware.nixosModules.common-pc-laptop-ssd
    ./disko-config.nix
  ];

  boot = {
    loader.grub = {
      enable = true;
      # devices = [ "/dev/disk/by-id/ata-ST9750420AS_6WS19RSB" ];
      memtest86.enable = true;
    };
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

  swapDevices = [];
}
