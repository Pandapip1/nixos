{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    libva
    libdrm
    pavucontrol
    linuxPackages.v4l2loopback
    v4l-utils
    immersed-vr
  ];

  boot = {
    kernelModules = [ "v4l2loopback" "snd-aloop" ];
    extraModulePackages = with config.boot.kernelPackages; [ pkgs.linuxPackages.v4l2loopback ];
    extraModprobeConfig =
      ''
      options v4l2loopback exclusive_caps=1 card_label="v4l2loopback Virtual Camera"
      '';
  };
}
