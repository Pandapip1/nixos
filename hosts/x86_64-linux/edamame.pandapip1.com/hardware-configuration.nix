{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  # GRUB, because I prefer GRUB to systemd-boot
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      efiSupport = true;
      devices = lib.mkForce [ "/dev/disk/by-id/TODO" ];
      memtest86.enable = true;
    };
  };

  # Kernel stuff
  boot.kernelParams = [ ];
  boot.initrd.availableKernelModules = [
    # TODO
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [
    # TODO
  ];
  boot.extraModulePackages = [ ];

  # Use disko for filesystem management
  imports = [ ./disko-config.nix ];
}
