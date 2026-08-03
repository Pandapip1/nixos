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
  nix-gc.configurationLimit = 3;

  # Packages I use here
  environment.systemPackages = with pkgs; [
    claude-code
  ];

  system.stateVersion = "26.11";
}
