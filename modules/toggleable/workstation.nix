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

    environment.systemPackages = with pkgs; [
      adwaita-icon-theme-legacy
    ];

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

    # Use COSMIC DE
    services.displayManager.cosmic-greeter.enable = true;
    services.desktopManager.cosmic.enable = true;

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
    programs.gnupg.agent.pinentryPackage = pkgs.pinentry-gtk2;
  };
}
