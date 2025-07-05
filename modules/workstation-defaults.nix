# Sane defaults for a workstation
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options = {
    defaults.workstation = lib.mkEnableOption "workstation defaults";
  };

  config = lib.mkIf config.defaults.workstation {
    services.pcscd.enable = true;
    
    hardware.mcelog.enable = true;
    hardware.gpgSmartcards.enable = true;
    hardware.bluetooth.enable = true;
    hardware.trackpoint.enable = true;
    services.pulseaudio.enable = false; # Use pipewire instead
    hardware.flipperzero.enable = true;
    hardware.usb-modeswitch.enable = true;

    services.hardware.bolt.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    environment.systemPackages = with pkgs; [
      adwaita-icon-theme-legacy
    ];

    location.provider = "geoclue2";

    # Enable kubo, an IPFS client
    services.kubo = {
      enable = lib.mkDefault true;
      autoMount = lib.mkDefault true;
      enableGC = lib.mkDefault true;
      localDiscovery = lib.mkDefault false;
      # Use port 4030 by default (leave port 8080 alone)
      # This isn't standard, and was chosen because it's kinda near 4000, which is also used by ipfs
      settings.Addresses.Gateway = lib.mkDefault [
        "/ip4/127.0.0.1/tcp/4030"
        "/ip6/::1/tcp/4030"
      ];
    };

    # kmscon for fancier hardware-accelerated tty
    services.kmscon = {
      enable = true;
      hwRender = true;
    };
  
    services.udev.packages = with pkgs; [
      xr-hardware
      android-udev-rules
    ];

    fonts = {
      enableDefaultPackages = true;
      fontDir.enable = true;
      fontconfig = {
        enable = true;
        defaultFonts = {
          # Use Noto for everything
          serif = [ "Noto Serif" ];
          sansSerif = [ "Noto Sans" ];
          monospace = [ "Noto Mono" ];
          emoji = [ "Noto Color Emoji" ];
        };
        useEmbeddedBitmaps = true;
      };
      packages = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
    };
  };
}
