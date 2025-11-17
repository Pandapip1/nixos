{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./graphical.nix
  ];

  optimizations.lean.enable = true;

  services.pipewire.systemWide = true;

  environment.systemPackages = with pkgs; [
    xastir
    direwolf-unstable
  ];
}
