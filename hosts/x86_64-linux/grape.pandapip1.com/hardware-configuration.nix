{
  nixos-hardware,
  ...
}:

{
  imports = [
    ./disko-config.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
