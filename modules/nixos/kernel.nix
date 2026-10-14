{
  lib,
  pkgs,
  ...
}:

{
  boot = {
    kernelPackages = lib.mkDefault (pkgs.linuxPackagesFor pkgs.linux_latest); # TODO: Switch back to RT kernel
    initrd.systemd.enable = true;
  };
}
