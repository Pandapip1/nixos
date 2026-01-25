{
  disko ? {},
  ...
}:

{
  imports = [ disko.nixosModules.default or null ];
  networking.hostId = "704589ef";
  disko.devices.disk = {
    root.device = "/dev/disk/by-id/ata-FTM24C325H_P717614-NBC6-B30B002";
    # data0.device = "/dev/disk/by-id/ata-ST8000DM004-2U9188_ZR16BF7F";
    # data1.device = "/dev/disk/by-id/ata-ST8000DM004-2U9188_ZR16EMW1";
  };
  # fileSystems."/data".options = [ "nofail" ]; # TODO find out why we need this!
  # Notably, https://github.com/nix-community/disko/blob/3a9450b26e69dcb6f8de6e2b07b3fc1c288d85f5/tests/zfs.nix#L12 also needs this
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
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = "/";
              };
            };
          };
        };
      };
      # data0 = {
      #   type = "disk";
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       zfs = {
      #         size = "100%";
      #         content = {
      #           type = "zfs";
      #           pool = "data";
      #         };
      #       };
      #     };
      #   };
      # };
      # data1 = {
      #   type = "disk";
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       zfs = {
      #         size = "100%";
      #         content = {
      #           type = "zfs";
      #           pool = "data";
      #         };
      #       };
      #     };
      #   };
      # };
      # optaneswap = {
      #   type = "disk";
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       swap = {
      #         size = "100%";
      #         content = {
      #           type = "swap";
      #           resumeDevice = true;
      #         };
      #       };
      #     };
      #   };
      # };
    };
    # zpool = {
    #   data = {
    #     type = "zpool";
    #     mode = "mirror";
    #     rootFsOptions = {
    #       compression = "lz4";
    #       "com.sun:auto-snapshot" = "true";
    #     };
    #     postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^data@blank$' || zfs snapshot data@blank";

    #     datasets = {
    #       "main" = {
    #         type = "zfs_fs";
    #         mountpoint = "/data";
    #       };
    #     };
    #   };
    # };
  };
}
