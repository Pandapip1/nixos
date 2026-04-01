{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.gnome.gnome-keyring.enable = false; # For some reason enabling cosmic enables gnome keyring. I want to use keepassxc thank you very much.

  programs.opengamepadui = {
    enable = true;
    inputplumber.enable = true;
    powerstation.enable = true;
    gamescopeSession.enable = true;
  };

  programs.steam = {
    enable = true;
    extest.enable = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    lutris
    prismlauncher
  ];

  system.stateVersion = "25.11";
}
