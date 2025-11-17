{
  config,
  lib,
  pkgs,
  ...
}:


{
  options.optimizations.lean.enable = lib.mkEnableOption "disk space saving optimizations";
}
