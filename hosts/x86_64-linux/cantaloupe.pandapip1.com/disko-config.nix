{
  networking.hostId = "704589ef";
  disko.devices.disk = {
    root.device = "/dev/disk/by-id/ata-FTM24C325H_P717614-NBC6-B30B002";
    data0.device = "/dev/disk/by-id/ata-ST8000DM004-2U9188_ZR16BF7F";
    data1.device = "/dev/disk/by-id/ata-ST8000DM004-2U9188_ZR16EMW1";
  };
  # Two independent, well-known ZFS-on-NixOS/systemd rough edges make this
  # dataset's mount unreliable enough at boot to need nofail:
  #
  # 1. disko sets a real (non-legacy) ZFS `mountpoint` property on `main`
  #    (lib/types/zfs_fs.nix's `_create`), so ZFS's own zfs-mount.service
  #    ("zfs mount -a") will try to auto-mount it natively - but disko *also*
  #    unconditionally emits a NixOS `fileSystems."/data"` entry for the same
  #    dataset (zfs_fs.nix's `_config`), which becomes its own systemd .mount
  #    unit. Both race to mount the same path; systemd has no notion that one
  #    "owns" it over the other. See
  #    https://toxicfrog.github.io/automounting-zfs-on-nixos/ for the
  #    canonical writeup of this race (the fix it recommends - mountpoint =
  #    "legacy" everywhere, dropping ZFS's own automount - trades this race
  #    for needing every dataset hand-listed in `fileSystems`, which disko
  #    doesn't do for you).
  # 2. Independent of (1): zfs-import-<pool>.service's own dependency
  #    structure onto local-fs.target makes pool import not reliably
  #    asynchronous even when its filesystems ARE marked nofail, per the
  #    still-open, unresolved nixpkgs issue
  #    https://github.com/NixOS/nixpkgs/issues/116678. This affects
  #    mountpoint=legacy datasets too, which is why disko's own upstream ZFS
  #    test carries the identical nofail+TODO on `/zfs_legacy_fs` (see the
  #    link below) despite that one NOT hitting race (1).
  #
  # Neither is a disko-specific bug with a small fix: (1) is an inherent
  # consequence of disko defaulting to native ZFS mountpoints while also
  # always registering a NixOS fileSystems entry, and (2) lives in nixpkgs'
  # zfs.nix module and has sat open+stale for years without a maintainer
  # committing to a resolution. nofail is the accepted mitigation both
  # upstream and here: it keeps a lost race or slow import from blocking
  # boot, at the cost of not being able to rely on /data being mounted by
  # the time other units that don't explicitly wait on it run.
  fileSystems."/data".options = [ "nofail" ];
  # disko's own ZFS test needs the identical, equally-unexplained-until-now
  # flag on its mountpoint=legacy dataset, for reason (2) above:
  # https://github.com/nix-community/disko/blob/3a9450b26e69dcb6f8de6e2b07b3fc1c288d85f5/tests/zfs.nix#L12
  disko.devices = {
    disk = {
      root = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              # MBR fallback
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
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
      data0 = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "data";
              };
            };
          };
        };
      };
      data1 = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "data";
              };
            };
          };
        };
      };
    };
    zpool = {
      data = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = {
          compression = "lz4";
          "com.sun:auto-snapshot" = "true";
        };
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^data@blank$' || zfs snapshot data@blank";

        datasets = {
          "main" = {
            type = "zfs_fs";
            mountpoint = "/data";
          };
        };
      };
    };
  };
}
