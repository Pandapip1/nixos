{ config, lib, nixos-hardware, ... }:

{
  imports = [
    # GNOME Desktop Environment
    ../environments/gnome.nix
    # Applications
    ../applications/chromium.nix
    ../applications/vector.nix
    ../applications/codium.nix
    ../applications/steam.nix
    ../applications/envision.nix
    ../applications/localsend.nix
    # Users
    ../users/gavin.nix
    # Hardware
    nixos-hardware.nixosModules.common-cpu-amd
    nixos-hardware.nixosModules.common-cpu-amd-pstate
    nixos-hardware.nixosModules.common-cpu-amd-zenpower
    nixos-hardware.nixosModules.common-gpu-amd
    nixos-hardware.nixosModules.common-pc
    nixos-hardware.nixosModules.common-pc-ssd
  ];

  programs.corectrl = {
    enable = true;
    gpuOverclock = {
      enable = true;
      ppfeaturemask = "0xffffffff";
    };
  };
  
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/9cc16f16-51cf-4556-bcdb-647f1ef0ced1";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/6181-AF10";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/4540c1ff-03b9-4119-a013-1fe791c5a6de"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp4s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp3s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
