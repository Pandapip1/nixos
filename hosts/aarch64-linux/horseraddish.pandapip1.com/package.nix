{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  optimizations.lean.enable = true;

  system.stateVersion = "26.05";
}
