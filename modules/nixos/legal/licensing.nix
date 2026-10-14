{
  lib,
  ...
}:

{
  # Would use even non redistributable firmware if it were compatible with allowUnfree = false
  # TODO: Open report
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
