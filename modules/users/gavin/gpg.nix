{
  home-manager.users.gavin = {
    programs = {
      gpg.enable = true;
    };
    services = {
      gpg-agent = {
        enable = true;
        enableScDaemon = true;
        enableSshSupport = true;
        enableExtraSocket = true;
        enableBashIntegration = true;
      };
    };
  };
}
