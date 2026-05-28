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
  };
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
