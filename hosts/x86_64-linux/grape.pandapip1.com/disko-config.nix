{
  disko ? {},
  ...
}:

{
  imports = [ disko.nixosModules.default or null ];
  disko.devices.disk = {
    # root.device = "/dev/disk/by-id/ata-P3-256_9X50427070023";
  };
  disko.devices = {
    disk = {
      root = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = { # MBR fallback
              size = "1M";
              type = "EF02";
            };
            ESP = {
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
              size = "16G";
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
