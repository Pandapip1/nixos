{
  pkgs,
  ...
}:

{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.systemd.enable = true;
  };
}
