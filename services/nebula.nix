{
  self,
  config,
  pkgs,
  ...
}:

let
  hostname = config.networking.hostName;
in
{
  environment.systemPackages = with pkgs; [
    nebula
  ];
  services.nebula.networks.nebula0 = {
    enable = true;
    settings = {
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
  };
}
