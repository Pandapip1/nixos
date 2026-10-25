{
  lib,
  pkgs,
  ...
}:

{
  boot = {
    kernelPackages = lib.mkDefault (pkgs.linuxPackagesFor pkgs.linux_latest); # TODO: Switch back to RT kernel
    # Scripted initrd was removed upstream; systemd-stage-1 is now the only
    # implementation, so setting this explicitly is a no-op nixpkgs rejects.
  };
}
