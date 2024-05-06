{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnupg
  ];

  services.pcscd.enable = true;
  
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
