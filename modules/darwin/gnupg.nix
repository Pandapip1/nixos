{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  home-manager.users.gavin.home.file = {
    ".gnupg/gpg-agent.conf" = {
      force = true;
      text = ''
        enable-ssh-support
      '';
    };

    ".gnupg/sshcontrol" = {
      force = true;
      text = ''
        # OpenPGP smart-card authentication subkey (CD96142D18BAD638)
        27BB49EFD13EFAA61051D73860164ED0A6E81F79
      '';
    };
  };
}
