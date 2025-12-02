{
  lib,
  pkgs,
  ...
}:

{
  boot = {
    kernelPackages = lib.mkDefault (pkgs.linuxPackagesFor pkgs.linux-rt_latest);
    initrd.systemd.enable = true;
  };
}
