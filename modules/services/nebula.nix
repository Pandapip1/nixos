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
    ca = "${self}/global_config/nebula/ca.crt";
    cert = let
      fqdn = if (config.networking.domain == null) then config.networking.hostName else "${config.networking.hostName}.${config.networking.domain}";
    in
      "${self}/hosts/${config.nixpkgs.hostPlatform.system}/${fqdn}/config/nebula/${hostname}.crt";
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
