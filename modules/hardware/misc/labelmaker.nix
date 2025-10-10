{
  pkgs,
  ...
}:

{
  services.udev.packages = with pkgs; [ labelle ];
}
