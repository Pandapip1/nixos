{ config, lib, pkgs, nix-software-center, nixos-conf-editor, ... }:

{
  # Enable dependencies
  imports = [
    ../services/pipewire.nix
    ../services/cups.nix
  ];

  services.displayManager = {
    enable = true;
    defaultSession = "gnome";
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
      gnome.enable = true;
    };
  };
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon gnome2.GConf ];

  # Configure installed packages
  environment.systemPackages = with pkgs; [
    blackbox-terminal
    gnome.adwaita-icon-theme
    thunderbird
    nextcloud-client
    keepassxc
    nix-software-center.packages.${system}.nix-software-center
    nixos-conf-editor.packages.${system}.nixos-conf-editor
    gnomeExtensions.appindicator
  ];
  services.xserver.excludePackages = with pkgs; [
    xterm
  ];

  # GNOME Extensions
  programs.dconf = {
    enable = true;
    profiles = {
      user.databases = [{
        settings = with lib.gvariant; {
          "org/gnome/shell".enabled-extensions = [
            "TEMP"
          ];
        };
      }];
    };
  };

  # Pinentry
  programs.gnupg.agent = {
    pinentryPackage = pkgs.pinentry-gnome3;
  };
}
