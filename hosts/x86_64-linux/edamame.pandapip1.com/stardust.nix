{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    stardust-xr-gravity
    stardust-xr-phobetor
    stardust-xr-magnetar
    stardust-xr-flatland
    stardust-xr-protostar
    stardust-xr-sphereland
    stardust-xr-atmosphere
  ];
}
