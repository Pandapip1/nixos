{
  lib,
  pkgs,
  ...
}:

{
  boot = {
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest_rt; # RT is a performance hit but I really like the fact that it's more consistent
    initrd.systemd.enable = true;
  };
}
