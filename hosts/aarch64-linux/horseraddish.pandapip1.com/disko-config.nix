{
  pkgs,
  nixos-rk3588,
  ...
}:

let
  inherit (pkgs.stdenv) hostPlatform;
  inherit (nixos-rk3588.packages.${hostPlatform}) u-boot-opi5pro;
in
{
  disko.devices.disk.nvme.device = "/dev/disk/by-id/TODO";
  disko.devices.disk = {
    sd = {
      type = "disk";
      device = "/dev/disk/by-path/platform-fe2c0000.mmc";
      content = {
        type = "gpt";
        partitions = {
          bootrom = {
            start = "34s";
            size = "32M";
            type = "EF02";
          };
        };
      };
      postCreateHook = ''
        dd if=${u-boot-opi5pro}/idbloader.img of=$device seek=64    conv=fsync,notrunc
        dd if=${u-boot-opi5pro}/u-boot.itb    of=$device seek=16384 conv=fsync,notrunc
      '';
    };
    nvme = {
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            start = "32M";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
