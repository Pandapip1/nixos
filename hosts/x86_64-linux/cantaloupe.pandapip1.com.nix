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

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "firewire_ohci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" 
"nvme" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems = {
    "/" = {
      fsType = "btrfs";
      device = "/dev/disk/by-label/NIXROOT";
      options = [
        "subvol=@"
        "compress=lzo"
        "noatime"
      ];
    };
    "/boot" = {
      fsType = "vfat";
      device = "/dev/disk/by-label/NIXBOOT";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/swap";
    }
  ];

  # AI Stuff
  services.open-webui = {
    enable = true;
    openFirewall = false; # Local-only, thank you
    host = "localhost"; # Again, still local-only please
    port = 7890; # Just a random free port
    environment = {
      WEBUI_AUTH = "False";
      GLOBAL_LOG_LEVEL = "CRITICAL";
    };
  };
  services.ollama = {
    enable = true;
    host = "localhost"; # Still just localhost thanks
    # Default port is acceptable
    loadModels = [
      "deepseek-r1"
      "gemma3n"
      "llama2-uncensored"

      # For Continue
      "nomic-embed-text:latest"
      "llama3.1:8b"
      "qwen2.5-coder:1.5b-base"
    ];
    acceleration = false; # No ROCm or CUDA on my laptop with an intel iGPU :(
  };

  system.stateVersion = "25.11";
}
