{
  lib,
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
  nixbuild-net = {
    # enable = true;
    crossOnly = true;
  };

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
  # hardware.spacenavd.enable = true;

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

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
  };

  # Testing inputplumber
  services.inputplumber.enable = true;

  # GNOME settings daemon
  services.gnome.gnome-settings-daemon.enable = true;

  hardware.hackrf.enable = true;
  hardware.rtl-sdr.enable = true;

  services.speechd.enable = true;
  programs.qgroundcontrol.enable = true;

  programs.nixpkgs-vet.enable = true;

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

  services.autoaspm.enable = lib.mkForce false; # Causes issues on my t480s

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
