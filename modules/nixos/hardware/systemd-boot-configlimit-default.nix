{
  lib,
  config,
  ...
}:

{
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault config.nix-gc.profiles.system.configurationLimit;
}
