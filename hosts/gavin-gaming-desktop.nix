{ nixos-hardware, pkgs ? null, lib ? null, ... }:

{
  imports = [
    # Applications
    # ../applications/chromium.nix
    ../applications/codium.nix
    ../applications/steam.nix
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
  
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelParams = [
    # Enable PCI passthrough
    "iommu=pt"
  ];
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

  programs = {
    qgroundcontrol.enable = true;
    immersed-vr.enable = true;
    minecraft-client.enable = true;
    localsend.enable = true;
    envision.enable = true;
    corectrl = {
      enable = true;
      gpuOverclock = {
        enable = true;
        ppfeaturemask = "0xffffffff";
      };
    };
    alvr = {
      enable = true;
      openFirewall = true;
    };
  };

  # Additional KWin session
  #services.desktopManager.plasma6.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
} // (if pkgs == null then {} else {
  #programs.ssh.askPassword = lib.mkForce "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
})
