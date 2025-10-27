{
  lib,
  self,
  config,
  ...
}:

let
  hostname = config.networking.hostName;
in
{
  services.nebula.networks.nebula0 = {
    enable = lib.mkDefault false;
    ca = "${self}/config/nebula/ca.crt";
    cert = "${self}/config/nebula/${hostname}.crt";
    key = "/etc/secrets/nebula/${hostname}.key";
    staticHostMap = {
      "10.0.0.1" = [
        "64.23.155.119:4242"
        "lighthouse.3webs.org:4242"
      ];
    };
    lighthouses = [
      "10.0.0.1"
    ];
    relays = [
      "10.0.0.1"
    ];
    firewall = {
      outbound = [
        {
          host = "any";
          port = "any";
          proto = "any";
        }
      ];
      inbound = [
        {
          host = "any";
          port = "any";
          proto = "any";
        }
      ];
    };
    settings = {
      punchy.punch = true;
    };
  };
  secrets = lib.mkIf config.services.nebula.networks.nebula0.enable {
    nebula.ownership = {
      # TODO: Upstream patch to allow setting per-network user & group, right now hardcode
      user = "nebula-nebula0";
      group = "nebula-nebula0";
    };
  };
}
