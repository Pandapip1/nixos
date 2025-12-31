{
  pkgs,
  ...
}:

let
  inherit (pkgs) lib;
in
{
  nixpkgs.overlays = [
    (_: prev: {
      cosmic-applets = prev.cosmic-applets.overrideAttrs {
        src = pkgs.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "cosmic-applets";
          rev = "14deb0d4aad0b8b210f52c48d3b7486f4ff725e1";
          hash = "sha256-KRpaevv4DF32CoZNfhSs6u9WPYNB3n01qpLiZy+CFbU=";
        };
      };
    })
  ];
}
