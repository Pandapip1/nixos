{
  imports = [
    ./hardware-configuration.nix
    ./ai.nix
    ./nginx.nix
    ./linux-isos.nix
    ./jellyfin.nix
  ];

  services.openssh = {
    enable = true;
  };

  system.stateVersion = "25.11";
}
