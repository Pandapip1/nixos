{
  pkgs,
  ...
}:

{
  hardware.pcmcia.enable = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
}
