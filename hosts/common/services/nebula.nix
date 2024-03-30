{ self, hostname, config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nebula
  ];
  services.nebula.networks.nebula0 = {
    enable = true;
    isLighthouse = false;
    cert = builtins.toFile "nebula-${hostname}.crt" (builtins.readFile "${self}/config/nebula/${hostname}.crt");
    key = "/etc/secrets/nebula/${hostname}.key";
    ca = builtins.toFile "nebula-ca.crt" (builtins.readFile "${self}/config/nebula/ca.crt");
    lighthouses = [
      "10.0.0.1"
    ];
    staticHostMap = {
      "10.0.0.1" = [
        "64.23.155.119:4242"
        # TODO: IPv6
        "lighthouse.3webs.org:4242"
      ];
    };
    tun = {
      disable = false;
      device = "nebula0";
    };
    firewall = {
      inbound = [ 
        # No rules yet
      ];
      outbound = [
        { # Allow all outbound traffic
          host = "any";
          port = "any";
          proto = "any";
        }
      ];
    };
  };
  systemd.services."nebula@nebula0".serviceConfig = lib.mkForce {
    User = lib.mkForce "root";
    Group = lib.mkForce "root";
    LockPersonality = lib.mkForce false;
    NoNewPrivileges = lib.mkForce false;
    ProtectClock = lib.mkForce false;
    ProtectControlGroups = lib.mkForce false;
    ProtectHome = lib.mkForce false;
    ProtectHostname = lib.mkForce false;
    ProtectKernelLogs = lib.mkForce false;
    ProtectKernelModules = lib.mkForce false;
    ProtectKernelTunables = lib.mkForce false;
    ProtectProc = lib.mkForce "default";
    ProtectSystem = lib.mkForce false;
    RestrictNamespaces = lib.mkForce false;
    RestrictSUIDSGID = lib.mkForce false;
  };
}
