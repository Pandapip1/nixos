{
  lib,
  ...
}:

{
  nix-gc.profiles.system.configurationLimit = lib.mkDefault 16;
}
