{ config, lib, pkgs, nix-software-center, nixos-conf-editor, ... }:

{
  # Enable dependencies
  imports = [
    ../services/pipewire.nix
    ../services/cups.nix
  ];

  services.displayManager = {
    enable = true;
    defaultSession = "Hyprland";
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
    gnome.adwaita-icon-theme
  ];
  services.xserver.excludePackages = with pkgs; [
    xterm
  ];

  # Pinentry
  programs.gnupg.agent = {
    pinentryPackage = pkgs.pinentry-gnome3;
  };
}
