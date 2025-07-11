{
  pkgs,
  nixos-hardware,
  ...
}:

{
  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-t480s
  ];

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

  # Enable nixbuild.net, but only for building to other systems
  # nixbuild-net = {
  #   enable = true;
  #   crossOnly = true;
  # };

  services.nebula.networks.nebula0.enable = true;

  # Enable ModemManager
  networking.modemmanager.enable = true;

  programs = {
    localsend.enable = true;
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  hardware.spacenavd.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/941197bb-1946-4607-8a36-0a71f3ccb918";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F854-0FE7";
    fsType = "vfat";
  };

  swapDevices = [ ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
  };

  # GNOME settings daemon
  services.gnome.gnome-settings-daemon.enable = true;

  # COSMIC DE
  services.graphical-desktop.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-qt;

  hardware.hackrf.enable = true;
  hardware.rtl-sdr.enable = true;

  services.speechd.enable = true;
  programs.qgroundcontrol.enable = true;

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
    ];
    acceleration = false; # No ROCm or CUDA on my laptop with an intel iGPU :(
  };

  programs.vscode.enable = true;

  # Undervolt (tested stable using stress-ng --<cpu 8/gpu 32> --verify --timeout 5s at both battery saver and performance power modes)
  services.undervolt = {
    enable = true;
    coreOffset = -80;
    uncoreOffset = -20;
    gpuOffset = -50;
    analogioOffset = 0;
  };
  services.udev.packages = with pkgs; [ labelle ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
