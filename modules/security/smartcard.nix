{
  pkgs,
  ...
}:

{
  hardware.gpgSmartcards.enable = true;
  services.pcscd.enable = true;
  hardware.nfc-nci.enable = true;
  environment.systemPackages = with pkgs; [
    global-platform-pro
  ];
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    enableExtraSocket = true;
    enableBrowserSocket = true;
  };
}
