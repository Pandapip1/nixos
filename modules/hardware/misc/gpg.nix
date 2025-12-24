{
  hardware.gpgSmartcards.enable = true;
  # services.pcscd.enable = true; # Use internal CCID instead
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    enableExtraSocket = true;
    enableBrowserSocket = true;
  };
}
