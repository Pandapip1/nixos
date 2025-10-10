{
  pkgs,
  ...
}:

{
  hardware.mcelog.enable = pkgs.stdenv.hostPlatform.isi686 || pkgs.stdenv.hostPlatform.isx86_64;
}
