{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";

      content = {
        type = "gpt";

        partitions = {
          bios = {
            size = "1M";
            type = "EF02";
          };
          esp = {
            size = "256M";
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
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
