{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  optimizations.lean.enable = true;

  # The vendor rk3588 kernel doesn't support CONFIG_ZSWAP.
  zswap.enable = lib.mkForce false;

  system.stateVersion = "26.05";
}
