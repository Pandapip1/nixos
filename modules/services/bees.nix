{
  services.beesd.filesystems = {
    root = {
      spec = "/";
      hashTableSizeMB = 2048;
      verbosity = "crit";
      extraOptions = [ "--loadavg-target" "5.0" ];
    };
  };
}
