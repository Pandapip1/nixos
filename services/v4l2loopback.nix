{ config, pkgs, hostname, ... }:
{
  boot = {
    kernelModules = [ "v4l2loopback" "snd-aloop" ];
    extraModulePackages = with config.boot.kernelPackages; [ pkgs.linuxPackages.v4l2loopback ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="v4l2loopback Virtual Camera"
    '';
  };
  environment.systemPackages = with pkgs; [
    v4l-utils
  ];
}
