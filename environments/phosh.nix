{ config, lib, pkgs, ... }:

{
  # Enable dependencies
  imports = [
    ../services/cups.nix
  ];

  services.displayManager = {
    enable = true;
    defaultSession = "phosh";
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
    desktopManager = {
      phosh = {
        enable = true;
        group = "users";
      };
    };
  };
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon gnome2.GConf ];

  # Configure installed packages
  environment.systemPackages = with pkgs; [
    blackbox-terminal
    gnome.adwaita-icon-theme
    thunderbird
    gnomeExtensions.appindicator
  ];
  services.xserver.excludePackages = with pkgs; [
    xterm
  ];

  # Pinentry
  programs.gnupg.agent = {
    pinentryPackage = pkgs.pinentry-gnome3;
  };
}
