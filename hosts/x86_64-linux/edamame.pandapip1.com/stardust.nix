{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    stardust-xr-gravity
    # stardust-xr-phobetor and stardust-xr-magnetar and stardust-xr-sphereland
    # were removed from nixpkgs (2026-07-04): no longer compatible with
    # current Stardust XR server versions.
    stardust-xr-flatland
    stardust-xr-protostar
    stardust-xr-atmosphere
  ];
}
