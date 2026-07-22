{
  disko,
  pkgs,
  nixos-rk3588,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (nixos-rk3588.packages.${system}) u-boot-opi5pro;
in
{
  imports = [ disko.nixosModules.default ];

  disko.devices.disk = {
    nvme.device = "/dev/disk/by-id/nvme-eui.2c3ebf30353133300000000000000000";
    nvme.imageSize = "256060514304";
    sd.imageSize = "15634268160";

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
          boot = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
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
