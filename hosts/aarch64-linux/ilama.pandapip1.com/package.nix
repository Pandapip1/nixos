{
  pkgs,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  # Use COSMIC DE
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.gnome.gnome-keyring.enable = false; # For some reason enabling cosmic enables gnome keyring. I want to use keepassxc thank you very much.

  # Severely disk constrained
  nix-gc.profiles.system.configurationLimit = 3;

  # Packages I use here
  extraProfiles.singleton.packages = with pkgs; [
    claude-code
  ];

  system.stateVersion = "26.11";
}
