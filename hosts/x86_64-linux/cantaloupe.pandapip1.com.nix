{ config, lib, pkgs, modulesPath, ... }:

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

  services.openssh = {
    enable = true;
  };

  # AI Stuff
  services.open-webui = {
    enable = true;
    port = 7890; # Just a random free port
    openFirewall = true;
    environment = {
      WEBUI_URL = "http://cantaloupe.local:7890";
      ENABLE_LOGIN_FORM = "false";
      ENABLE_OAUTH_SIGNUP = "true";
      ENABLE_OAUTH_GROUP_MANAGEMENT = "true";
      ENABLE_OAUTH_GROUP_CREATION = "true";
      OAUTH_GROUP_CLAIM = "groups";
      OAUTH_CLIENT_ID = "65f60599-44c9-476d-91b3-2728a8a9b7f0";
      OAUTH_CLIENT_SECRET = "ruu00mwn0x1tCzZWukSRjJuRj3zwiWZd"; # TODO: Find a way to avoid publicly sharing the secret; this should be fine as it doesn't have a service account
      OPENID_PROVIDER_URL = "https://keycloak.berry.pandapip1.com/realms/pandaport/.well-known/openid-configuration";
      OAUTH_PROVIDER_NAME = "PandaPort";
      OAUTH_SCOPES = "openid email profile groups";
      GLOBAL_LOG_LEVEL = "CRITICAL";
    };
  };
  services.ollama = {
    enable = true;
    openFirewall = true; # Make ollama accessible across network
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
