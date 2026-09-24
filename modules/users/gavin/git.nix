{
  home-manager.users.gavin = {
    programs.git = {
      enable = true;
      settings.user = {
        name = "Gavin John";
        email = "gavinnjohn@gmail.com";
      };
      settings.credential = {
        "https://github.com".helper =
          ''!f() { nix-shell -p gh --run "gh auth git-credential $1"; }; f'';
        "https://gist.github.com".helper =
          ''!f() { nix-shell -p gh --run "gh auth git-credential $1"; }; f'';
        "https://gitlab.freedesktop.org".helper =
          ''!f() { nix-shell -p glab --run "glab auth git-credential $1"; }; f'';
        "https://gitlab.com".helper =
          ''!f() { nix-shell -p glab --run "glab auth git-credential $1"; }; f'';
      };
      signing = {
        format = "openpgp";
        signByDefault = true;
      };
      maintenance.enable = true;
    };
  };
}
