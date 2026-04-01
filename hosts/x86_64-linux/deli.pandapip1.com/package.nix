{
  imports = [
    ./hardware-configuration.nix
  ];

  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.gnome.gnome-keyring.enable = false; # For some reason enabling cosmic enables gnome keyring. I want to use keepassxc thank you very much.

  system.stateVersion = "25.11";
}
