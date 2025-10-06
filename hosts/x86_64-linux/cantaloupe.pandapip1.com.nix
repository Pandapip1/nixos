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

  # Hardware
  hardware.amdgpu.opencl.enable = true;

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

  # AI Stuff
  services.open-webui = {
    enable = true;
    port = 7890; # Just a random free port
    environment = {
      WEBUI_AUTH = "False";
      GLOBAL_LOG_LEVEL = "CRITICAL";
    };
  };
  services.ollama = {
    enable = true;
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
    acceleration = "rocm";
    rocmOverrideGfx = "9.0.6"; # gfx906 (Instinct MI50)
  };

  system.stateVersion = "25.11";
}
