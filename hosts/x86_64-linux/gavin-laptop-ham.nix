{
  lib,
  pkgs,
  nixos-hardware,
  ...
}:

{
  imports = [
    # Services
    # TODO: Add certs for nebula
    #../../services/nebula.nix
    # Applications
    ../../applications/codium.nix
    # Users
    ../../users/gavin.nix
    # Hardware
    # TODO: nixos-hardware profile
  ];

  programs = {
    xastir.enable = true;
  };

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "snd-aloop" ];
  boot.extraModulePackages = [ ];
  boot.extraModprobeConfig = ''
    options snd-aloop index=1 id=APRS-Loop pcm_substreams=1 enable=1
  '';

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/ce939f6b-10d0-40b1-8d88-bf720da3052b";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/7701-94D9";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    grub = {
      enable = true;
      device = "/dev/sda";
      default = "saved";
    };
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
  environment.etc."xdg/baloofilerc".source = (pkgs.formats.ini {}).generate "baloorc" {
    "Basic Settings" = {
      "Indexing-Enabled" = false;
    };
  };

  system.stateVersion = lib.mkForce "25.05";
}
