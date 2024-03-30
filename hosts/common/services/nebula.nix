{ self, hostname, config, lib, pkgs, systemd, ... }:

rec {
  environment.systemPackages = with pkgs; [
    nebula
  ];
  systemd.services."nebula@nebula0-fixed" = {
    enable = true;
    description = "Fixed nebula VPN service for nebula0";
    wants = [ "basic.target" "network-online.target" "nss-lookup.target" "time-sync.target" ];
    after = [ "basic.target" "network.target" "network-online.target" ];
    before = [ "sshd.service" ];
    serviceConfig = let ExecStart = systemd.services."nebula@nebula0".serviceConfig.ExecStart; in {
      Type = "notify";
      NotifyAccess = "main";
      SyslogIdentifier = "nebula0";
      ExecReload = "/run/current-system/sw/bin/kill -HUP $MAINPID";
      ExecStart = "/run/current-system/sw/bin/nebula -config ${
        builtins.toFile "nebula-config-${hostname}.yml" (
          "pki:\n" +
          "  ca: ${builtins.toFile "nebula-ca.crt" (builtins.readFile "${self}/config/nebula/ca.crt")}\n" +
          "  cert: ${builtins.toFile "nebula-${hostname}.crt" (builtins.readFile "${self}/config/nebula/${hostname}.crt")}\n" +
          "  key: /etc/secrets/nebula/${hostname}.key\n\n" +
          builtins.readFile "${self}/config/nebula/config-${hostname}.yml"
        )
      }";
      Restart = "always";
    };
    unitConfig.StartLimitIntervalSec = 0;
  };
}
