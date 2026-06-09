{
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="058f", ATTRS{idProduct}=="9540", ATTR{power/control}="on", ATTR{power/autosuspend_delay_ms}="-1"
  '';
}
