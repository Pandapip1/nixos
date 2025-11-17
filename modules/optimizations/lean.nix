{
  config,
  lib,
  pkgs,
  ...
}:


{
  options.optimizations.lean.enable = lib.mkEnableOption "disk space saving optimizations";

  config = lib.mkIf config.optimizations.lean.enable {
    nix-gc.configurationLimit = 2;
  };
}
