{ config, lib, pkgs, nix-software-center, nixos-conf-editor, ... }:

{
  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.xserver = {
    enable = true;
    libinput.enable = true;
    layout = "us";
    xkbVariant = "";
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
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true;
  };

  # Configure installed packages
  environment.systemPackages = with pkgs; [
    thunderbird
    nextcloud-client
    keepassxc
    nix-software-center.packages.${system}.nix-software-center
    nixos-conf-editor.packages.${system}.nixos-conf-editor
    gnomeExtensions.remove-alttab-delay-v2
    gnomeExtensions.appindicator
  ];
  services.xserver.excludePackages = with pkgs; [
    xterm
  ];
  environment.gnome.excludePackages = with pkgs; with pkgs.gnome; [
    baobab      # disk usage analyzer
    cheese      # photo booth
    eog         # image viewer
    gedit       # text editor
    simple-scan # document scanner
    totem       # video player
    yelp        # help viewer
    evince      # document viewer
    file-roller # archive manager
    geary       # email client
    seahorse    # password manager

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

  # GNOME Performance patch
  nixpkgs.overlays = [
    (final: prev: {
      gnome = prev.gnome.overrideScope' (gnomeFinal: gnomePrev: {
        mutter = gnomePrev.mutter.overrideAttrs ( old: {
          src = pkgs.fetchgit {
            url = "https://gitlab.gnome.org/vanvugt/mutter.git";
            # GNOME 45: triple-buffering-v4-45
            rev = "0b896518b2028d9c4d6ea44806d093fd33793689";
            sha256 = "sha256-mzNy5GPlB2qkI2KEAErJQzO//uo8yO0kPQUwvGDwR4w=";
          };
        } );
      });
    })
  ];
}
