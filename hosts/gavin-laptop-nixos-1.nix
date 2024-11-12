{ nixos-hardware, ... }:

{
  imports = [
    # Services
    ../services/nebula.nix
    # Applications
    ../applications/chromium.nix
    ../applications/codium.nix
    # Users
    ../users/gavin.nix
    # Hardware
    nixos-hardware.nixosModules.lenovo-thinkpad-t480s
  ];

  programs = {
    localsend.enable = true;
    envision.enable = true;
    # zed.enable = true;
    qgroundcontrol.enable = true;
  };

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

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

  # KDE Plasma
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
}
