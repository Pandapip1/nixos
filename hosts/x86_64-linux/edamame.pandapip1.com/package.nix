{
  pkgs,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  # Graphical greeter
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.gnome.gnome-keyring.enable = false; # For some reason enabling cosmic enables gnome keyring. I want to use keepassxc thank you very much.

  # Monado
  services.monado = {
    enable = true;
    defaultRuntime = true;
  };

  # Motoc
  environment.systemPackages = with pkgs; [
    motoc
  ];

  system.stateVersion = "25.11";
}
