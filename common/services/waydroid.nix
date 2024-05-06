{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wl-clipboard
  ];
  virtualisation.waydroid.enable = true;
  virtualisation.lxd.enable = true;
}
