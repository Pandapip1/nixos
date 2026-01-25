{
  disko ? {},
  ...
}:

{
  imports = [ disko.nixosModules.default or null ];
  disko.devices.disk = {
    root.device = "/dev/disk/by-id/nvme-Samsung_SSD_990_EVO_Plus_1TB_S7U5NJ0Y601088H";
    optaneswap.device = "/dev/disk/by-id/ata-INTEL_MEMPEK1J016GAL_PHBT90940AMX016N";
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
      optaneswap = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            swap = {
              size = "24G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
          };
        };
      };
    };
  };
}
