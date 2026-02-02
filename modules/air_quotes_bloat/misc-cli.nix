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
    nixfmt
    cdrkit
    tree
    vulnix
    lynis
  ];
}
