{
  lib,
  nixos-rk3588,
  ...
}:

{
  imports = [
    nixos-rk3588.nixosModules.boards.orangepi5pro.core
    ./disko-config.nix
  ];

  boot.loader = {
    grub.enable = lib.mkForce false;
    generic-extlinux-compatible.enable = lib.mkForce true;
  };
}
