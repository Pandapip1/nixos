{
  imports = [
    ./hardware-configuration.nix
    ./ai.nix
  ];

  services.openssh = {
    enable = true;
  };

  system.stateVersion = "25.11";
}
