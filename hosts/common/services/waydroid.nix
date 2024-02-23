{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wl-clipboard
    lxd
    waydroid
  ];
  virtualisation.waydroid.enable = true;
  virtualisation.lxd.enable = true;
}
