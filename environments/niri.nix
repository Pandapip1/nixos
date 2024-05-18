{ config, lib, pkgs, niri-flake, ... }:

{
  # Add niri.nixosModules.niri to the list of modules
  imports = [
    niri-flake.nixosModules.niri
  ];
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri;

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
    blackbox-terminal
    gnome.adwaita-icon-theme
  ];
  programs.niri.settings.binds = {
    "Mod+T".action.spawn = "blackbox";
    "Mod+D".action.spawn = "fuzzel";
  };
}
