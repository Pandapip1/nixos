{
  lib,
  config,
  pkgs,
  ...
}:

let
  # Pulled and lightly modified from official NixOS wiki page for zfs on 2025-10-16
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestZFSKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  # GRUB, because I prefer GRUB to systemd-boot
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      efiSupport = true;
      devices = lib.mkForce [ "/dev/disk/by-id/ata-FTM24C325H_P717614-NBC6-B30B002" ];
      memtest86.enable = true;
    };
  };

  # Kernel stuff
  boot.kernelPackages = lib.mkForce latestZFSKernelPackage; # ZFS support is mandatory
  boot.kernelParams = [ ];
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Use disko for filesystem management
  imports = [ ./disko-config.nix ];

  # Hardware
  hardware.amdgpu.opencl.enable = true;
  nixpkgs.config.rocmSupport = true;
}
