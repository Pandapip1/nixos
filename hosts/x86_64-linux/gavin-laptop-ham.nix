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
    ../../users/priyanka.nix
    # Hardware
    nixos-hardware.nixosModules.common-cpu-amd
    nixos-hardware.nixosModules.common-cpu-amd-pstate # TODO: Does this do anything
    nixos-hardware.nixosModules.common-gpu-amd
    # TODO: proper nixos-hardware profile
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
    { device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    grub = {
      enable = true;
      device = "/dev/disk/by-id/ata-INTEL_SSDSC2CW240A3_CVCV230302Q0240CGN";
      default = "saved";
    };
  };

  swapDevices = [ ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
  };

  environment.systemPackages = with pkgs; [
    direwolf
    gqrx
    xastir
  ];

  hardware.rtl-sdr.enable = true;
  hardware.hackrf.enable = true;

  # KDE Plasma
  services.graphical-desktop.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  environment.etc."xdg/baloofilerc".source = (pkgs.formats.ini {}).generate "baloorc" {
    "Basic Settings" = {
      "Indexing-Enabled" = false;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
