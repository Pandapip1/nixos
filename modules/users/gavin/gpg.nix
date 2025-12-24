{
  config,
  ...
}:

{
  home-manager.users.gavin = {
    programs = {
      gpg = {
        enable = true;
        homedir = "${config.home-manager.users.gavin.xdg.dataHome}/gnupg";
        
        scdaemonSettings = { # Why are the settings here?!?!
          # For some reason YubiKey doesn't like CCID
          disable-ccid = true;
        };

        settings = {
          keyserver = [
            "hkps://keys.openpgp.org"
            "hkps://keys.mailvelope.com"
            "hkps://keyserver.ubuntu.com:443"
            "hkps://pgpkeys.eu"
            "hkp://zkaan2xfbuxia2wpf7ofnkbz6r5zdbbvxbunvp5g2iebopbfc4iqmbad.onion"
          ];
          auto-key-locate = "wkd,dane,local";
          auto-key-retrieve = true;
          list-options = [
            "show-unusable-subkeys"
            "show-uid-validity"
          ];
          verify-options = "show-uid-validity";
          require-secmem = true;
          with-key-origin = true;
          with-fingerprint = true;
          armor = true;
          throw-keyids = true;
          no-symkey-cache = true;
        };
      };
    };
    services = {
      gpg-agent = {
        enable = true;
        enableScDaemon = true; # Use internal CCID


        # SSH forwarding
        enableSshSupport = true;
        enableExtraSocket = true;

        # Enable all the integrations please
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        enableNushellIntegration = true;

        # TODO: See what of this can be eliminated
        extraConfig = ''
          ttyname $GPG_TTY
          pinentry-program /run/current-system/sw/bin/pinentry
        '';
      };
    };
  };
}
