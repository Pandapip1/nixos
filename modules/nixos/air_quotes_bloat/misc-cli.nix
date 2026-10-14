{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    killall
    usbutils
    pciutils
    gdb
    cdrkit
    vulnix
    lynis
    # Performance debugging
    perf
    trace-cmd
    rt-tests
  ];
}
