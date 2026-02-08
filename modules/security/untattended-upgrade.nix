{
  self,
  ...
}:

{
  system.autoUpgrade = {
    enable = true;
    flake = "git+https://codeberg.org/Pandapip1/nixos.git?shallow=1";
    flags = [
      "--print-build-logs"
      "--refresh"
    ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };
}
