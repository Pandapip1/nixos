{
  lib,
  pkgs,
  ...
}:
let
  oauthHelper = [
    "cache --timeout 21600"
    (lib.getExe pkgs.git-credential-oauth)
  ];
in
{
  home-manager.users.gavin = {
    programs.git = {
      enable = true;
      settings.user = {
        name = "Gavin John";
        email = "gavinnjohn@gmail.com";
      };
      settings.credential = {
        "https://github.com".helper = oauthHelper;
        "https://gist.github.com".helper = oauthHelper;
        "https://gitlab.freedesktop.org".helper = oauthHelper;
        "https://gitlab.com".helper = oauthHelper;
        "https://codeberg.org".helper = oauthHelper;
        "https://code.videolan.org".helper = oauthHelper;
      };
      signing = {
        format = "openpgp";
        signByDefault = true;
      };
      maintenance.enable = true;
    };
  };
}
