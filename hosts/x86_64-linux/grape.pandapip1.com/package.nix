{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./graphical.nix
  ];

  services.pipewire.systemWide = true;

  environment.systemPackages = with pkgs; [
    xastir
    direwolf-unstable
  ];
}
