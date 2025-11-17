{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./graphical.nix
  ];

  nix-gc.configurationLimit = 2; # Disk constrained

  services.pipewire.systemWide = true;

  environment.systemPackages = with pkgs; [
    xastir
    direwolf-unstable
  ];
}
