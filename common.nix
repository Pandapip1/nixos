{ lib, config, pkgs, hostname, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config = {
    overlays = [
      (final: prev: rec {
        /*
          python = prev.python.override {
            enableOptimizations = true;
            reproducibleBuild = false;
          };
          python3 = prev.python3.override {
            enableOptimizations = true;
            reproducibleBuild = false;
          };
          python313 = prev.python313.override {
            enableOptimizations = true;
            reproducibleBuild = false;
          };
          python312 = prev.python312.override {
            enableOptimizations = true;
            reproducibleBuild = false;
          };
          python311 = prev.python311.override {
            enableOptimizations = true;
            reproducibleBuild = false;
          };
          python310 = prev.python310.override {
            enableOptimizations = true;
            reproducibleBuild = false;
          };
          python39 = prev.python39.override {
            enableOptimizations = true;
            reproducibleBuild = false;
          };
          pythonPackages = python.pkgs;
          python3Packages = python3.pkgs;
          python313Packages = python313.pkgs;
          python312Packages = python312.pkgs;
          python311Packages = python311.pkgs;
          python310Packages = python310.pkgs;
          python39Packages = python39.pkgs;
        */
      })
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware.enableAllFirmware = true;

  time.timeZone = lib.mkForce null;
  location.provider = "geoclue2";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    firewall.enable = true;
  };

  environment.systemPackages = with pkgs; [
    git
    gnupg
    vim
  ];

  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    sharedModules = [
      {
        home.stateVersion = "23.11";
      }
    ];
  };

  services.pcscd.enable = true;
  
  hardware.mcelog.enable = true;
  hardware.gpgSmartcards.enable = true;
  hardware.bluetooth.enable = true;
  hardware.trackpoint.enable = true;
  hardware.pulseaudio.enable = false; # Use pipewire instead
  hardware.flipperzero.enable = true;
  hardware.usb-modeswitch.enable = true;

  services.hardware.bolt.enable = true;

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.udev = {
    enable = true;
    packages = with pkgs; [
      xr-hardware
      android-udev-rules
    ];
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    nerdfonts
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  programs.starship.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
