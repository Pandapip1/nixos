{
  home-manager.users.gavin = {
    programs.git = {
      settings.user = {
        name = "Gavin John";
        email = "gavinnjohn@gmail.com";
      };
      signing = {
        format = "gpg";
        signByDefault = true;
      };
      maintenance.enable = true;
    };
  };
}
