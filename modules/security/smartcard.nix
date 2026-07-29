{
  lib,
  pkgs,
  ...
}:

{
  hardware.gpgSmartcards.enable = true;
  services.pcscd = {
    enable = true;
    plugins = lib.mkForce [ pkgs.ccid ];
    extraArgs = [
      "--debug"
      "--apdu"
      "--color"
    ];
  };
  # systemd.services.pcscd.environment.LIBCCID_ifdLogLevel = "0x000F";
  services.fido2-hid-bridge.enable = true;
  environment.systemPackages = with pkgs; [
    global-platform-pro
  ];
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    enableExtraSocket = true;
    enableBrowserSocket = true;
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ENV{ID_SMARTCARD_READER}=="1", RUN+="${lib.getExe' pkgs.acl "setfacl"} -m u:pcscd:rw $env{DEVNAME}"
  '';

  home-manager.sharedModules = [
    ({ hmConfig, ... }: {
      programs.gpg = {
        enable = true;
        homedir = "${hmConfig.xdg.dataHome}/gnupg";
        scdaemonSettings = {
          disable-ccid = true;
          pcsc-shared = true;
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

      services.gpg-agent = {
        enable = true;
        enableScDaemon = true;
        enableExtraSocket = true;
        enableSshSupport = true;

        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        enableNushellIntegration = true;

        verbose = true;

        extraConfig = ''
          ttyname $GPG_TTY
          pinentry-program /run/current-system/sw/bin/pinentry
        '';
      };
    })
  ];
}
