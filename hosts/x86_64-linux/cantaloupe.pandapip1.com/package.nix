{
  imports = [
    ./hardware-configuration.nix
    ./ai.nix
    ./linux-isos.nix
    ./jellyfin.nix
    ./nginx.nix
  ];

  services.openssh = {
    enable = true;
  };

  services.nebula.networks.nebula0.enable = true;

  system.stateVersion = "25.11";
}
