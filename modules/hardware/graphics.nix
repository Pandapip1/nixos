{
  hardware.graphics = {
    enable = true;
    enable32Bit = pkgs.stdenvNoCC.hostPlatform.isx86_64;
  };
}
