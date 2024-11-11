{ config, lib, pkgs, ... }:

{
  # Enable dependencies
  imports = [
    ../services/cups.nix
  ];

  services.displayManager = {
    enable = true;
    defaultSession = "hyprland";
  };

  services.libinput.enable = true;

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
  };

  programs.hyprland.enable = true;

  # Configure installed packages
  environment.systemPackages = with pkgs; [
    blackbox-terminal
  ];
  services.xserver.excludePackages = with pkgs; [
    xterm
  ];

  # Pinentry
  programs.gnupg.agent = {
    pinentryPackage = pkgs.pinentry-gnome3;
  };
}
