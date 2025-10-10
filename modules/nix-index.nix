{
  programs.comma = {
    enable = true;
    package = pkgs.comma-with-db;
  };
  programs.nix-index = {
    enable = true;
    package = pkgs.nix-index-with-db;
  };
}
