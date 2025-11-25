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
    wsjtx
    gnuradio
    gqrx
    gpredict
    hamlib_4
    grig
    cubicsdr
    rtl-sdr
    sdrangel
  ];

  system.stateVersion = "25.11";
}
