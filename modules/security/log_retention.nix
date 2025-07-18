{
  services = {
    logrotate = {
      enable = true;
    };
    journald.extraConfig = ''
      MaxRetentionSec=5day
      SystemMaxUse=500M
    '';
  };
}
