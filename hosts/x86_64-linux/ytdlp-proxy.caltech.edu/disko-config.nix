{
  disko,
  ...
}:

{
  imports = [ disko.nixosModules.default ];
  disko.devices.disk = {
    root.device = "/dev/disk/by-id/ata-SanDisk_SDSSDRC032G_143235415892";
  };
  disko.devices = {
    disk = {
      root = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              # MBR
              size = "1M";
              type = "EF02";
            };
            ESP = {
              # EFI forward compatibility
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "4G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "btrfs";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
