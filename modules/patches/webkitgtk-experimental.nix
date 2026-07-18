{
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    (_: prev: {
      webkitgtk_6_0 = prev.webkitgtk_6_0.override { enableExperimental = true; };
      webkitgtk_4_1 = prev.webkitgtk_4_1.override { enableExperimental = true; };
    })
  ];
  environment.systemPackages = with pkgs; [
    epiphany
  ];
}
