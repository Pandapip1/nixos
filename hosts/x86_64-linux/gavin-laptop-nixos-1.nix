{
  pkgs,
  nixos-hardware,
  ...
}:

{
  imports = [
    # Services
    ../../services/nebula.nix
    ../../services/cups.nix
    # Applications
    # ../applications/chromium.nix
    ../../applications/codium.nix
    # Users
    ../../users/gavin.nix
    # Hardware
    nixos-hardware.nixosModules.lenovo-thinkpad-t480s
  ];

  programs = {
    localsend.enable = true;
  };

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  hardware.spacenavd.enable = true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/941197bb-1946-4607-8a36-0a71f3ccb918";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F854-0FE7";
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
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  programs.gnupg.agent.pinentryPackage = pkgs.pinentry-qt;

  services.speechd.enable = true;
  programs.qgroundcontrol.enable = true;

  # Undervolt (tested stable using stress-ng --<cpu 8/gpu 32> --verify --timeout 5s at both battery saver and performance power modes)
  /* services.undervolt = {
    enable = true;
    coreOffset = -100;
    uncoreOffset = 0;
    gpuOffset = 0;
    analogioOffset = 0;
  }; */
  services.udev.packages = with pkgs; [ labelle ];
}
