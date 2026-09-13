{
  services = {
    logrotate = {
      enable = true;
    };
    journald.settings.Journal = {
      MaxRetentionSec = "5day";
      SystemMaxUse = "500M";
    };
  };
}
