{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    killall
    btop
    dig
    usbutils
    pciutils
    gdb
    nixfmt-rfc-style
    cdrkit
  ];
}
