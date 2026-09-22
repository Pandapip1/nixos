{ lib, ... }:

{
  # Coredumps were piling up unpruned (233 files, 3.8G, going back weeks) and
  # helped drive / to 0 bytes free. Cap how much they're allowed to hold.
  systemd.coredump.settings.Coredump = {
    MaxUse = lib.mkDefault "1G";
    KeepFree = lib.mkDefault "5G";
  };
}
