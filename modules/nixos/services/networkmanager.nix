{
  lib,
  ...
}:

{
  networking = {
    networkmanager.enable = true;
    modemmanager.enable = lib.mkDefault true;
  };
}
