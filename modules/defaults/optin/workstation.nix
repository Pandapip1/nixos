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
    # Bring in more defaults
    defaults.audio = true;

    services.pcscd.enable = true;
    
    hardware.mcelog.enable = true;
    hardware.gpgSmartcards.enable = true;
    hardware.bluetooth.enable = true;
    hardware.trackpoint.enable = true;
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
      # enable = lib.mkDefault true;
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
      packages = (builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts)) ++ (with pkgs; [
        orbitron
      ]);
    };

    # Printing
    services.printing = {
      enable = true;
      startWhenNeeded = true;
      drivers = with pkgs; [
        cups-pdf-to-pdf
        gutenprint
        cups-idprt-tspl
      ];
    };

    # Use COSMIC greeter with KDE plasma :)
    services.displayManager.cosmic-greeter.enable = true;
    services.desktopManager.plasma6.enable = true;

    # Add GNOME polkit agent
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
    # And pinentry
    programs.gnupg.agent.pinentryPackage = pkgs.pinentry-gnome3;
  };
}
