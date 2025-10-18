{
  programs = {
    gpg.enable = true;
    gpg-agent = {
      enable = true;
      enableScDaemon = true;
      enableSshSupport = true;
      enableExtraSocket = true;
      enableBashIntegration = true;
    };
  };
}
