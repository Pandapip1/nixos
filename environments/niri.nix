{ config, lib, pkgs, niri-flake, ... }:

{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  services.displayManager = {
    enable = true;
  };
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
    };
    excludePackages = [ pkgs.xterm ];
  };
  environment.systemPackages = with pkgs; [
    fuzzel
    swaylock
    alacritty # fallback
    blackbox-terminal
    gnome.adwaita-icon-theme
  ];
}
