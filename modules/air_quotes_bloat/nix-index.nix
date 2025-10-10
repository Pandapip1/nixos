{
  lib,
  pkgs,
  ...
}:

{
  programs.comma = {
    enable = lib.mkDefault true;
    package = pkgs.comma-with-db;
  };
  programs.nix-index = {
    enable = lib.mkDefault true;
    package = pkgs.nix-index-with-db;
  };
}
