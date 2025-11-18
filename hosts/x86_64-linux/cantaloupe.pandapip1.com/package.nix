{
  imports = [
    ./hardware-configuration.nix
    ./ai.nix
    ./nginx.nix
  ];

  services.openssh = {
    enable = true;
  };

  system.stateVersion = "25.11";
}
