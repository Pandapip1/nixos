{
  config,
  lib,
  pkgs,
  modulesPath,
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
  # GRUB, since we're stuck on legacy BIOS
  boot.loader.grub = {
    enable = true;
    device = "/dev/disk/by-id/wwn-0x5f8db4c251202202";
    devices = lib.mkForce [];
    memtest86.enable = true; # Might as well!
  };

  # Kernel stuff
  boot.kernelPackages = lib.mkForce latestZFSKernelPackage; # ZFS support is mandatory
  boot.initrd.availableKernelModules = [
    "ahci"
    "ohci_pci"
    "ehci_pci"
    "pata_atiixp"
    "mpt3sas"
    "usbhid"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Use disko for filesystem management
  imports = [ ./disko-config.nix ];
}
