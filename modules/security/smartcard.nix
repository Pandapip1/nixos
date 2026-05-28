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
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ENV{ID_SMARTCARD_READER}=="1", RUN+="${lib.getExe' pkgs.acl "setfacl"} -m u:pcscd:rw $env{DEVNAME}"
  '';
}
