{
  pkgs,
  ...
}:

{
  services.udev.packages = with pkgs; [ nrf-udev ];
}
