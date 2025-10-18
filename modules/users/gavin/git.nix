{
  home-manager.users.gavin = {
    programs.git = {
      userName = "Gavin John";
      userEmail = "gavinnjohn@gmail.com";
      signing = {
        format = "gpg";
        signByDefault = true;
      };
      maintenance.enable = true;
      git-credential-oauth.enable = true;
      git-credential-keepassxc.enable = true;
    };
  };
}
