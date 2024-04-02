{ config, lib, pkgs, nix-software-center, nixos-conf-editor, ... }:

{
  # Enable dependencies
  imports = [
    ../services/pipewire.nix
    ../services/cups.nix
  ];

  services.xserver = {
    enable = true;
    libinput.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
    displayManager = {
      defaultSession = "gnome";
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
  environment.gnome.excludePackages = with pkgs; with pkgs.gnome; [
    baobab                # disk usage analyzer
    cheese                # photo booth
  eog                     # image viewer
    pkgs.gedit                 # text editor
    simple-scan           # document scanner
    totem                 # video player
    yelp                  # help viewer
    evince                # document viewer
    file-roller           # archive manager
    geary                 # email client
    seahorse              # password manager
    gnome.gnome-terminal  # terminal
    gnome-console   # terminal

    gnome-calculator gnome-calendar gnome-characters gnome-clocks gnome-contacts
    gnome-font-viewer gnome-logs gnome-maps gnome-music gnome-screenshot
    gnome-system-monitor gnome-weather gnome-disk-utility
    gnome-connections gnome-photos gnome-text-editor gnome-tour
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
