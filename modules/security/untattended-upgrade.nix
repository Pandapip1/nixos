{
  self,
  ...
}:

{
  system.autoUpgrade = {
    enable = true;
    flake = self.outPath;
    flags = [ "--print-build-logs" ];
    dates = "02:00";
    randomizedDelaySec = "45min";
  };
}
