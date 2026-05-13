{
  config,
  ...
}:

{
  security.acme = {
    certs = {
      "nixos.cache.pandapip1.com" = {};
    };
  };

  services = {
    atticd = {
      enable = true;
      settings = {
        listen = "[::1]:16206";
        api-endpoint = "https://nixos.cache.pandapip1.com/";
        storage = {
          type = "s3";
          bucket = "a7310486287908d892e70d10";
          region = "us-east-005";
          endpoint = "https://s3.us-east-005.backblazeb2.com";
        };
        compression.type = "xz";
      };
      environmentFile = "/etc/secrets/attic/env";
    };
  };
  # TODO: This should be in the upstream atticd module!
  users = {
    users."${config.services.atticd.user}" = {
      isSystemUser = true;
      group = "${config.services.atticd.group}";
    };
    groups."${config.services.atticd.group}" = {};
  };
  secrets.attic.ownership = {
    inherit (config.services.atticd) user group;
  };

  services.nginx = {
    virtualHosts = {
      "nixos.cache.pandapip1.com" = {
        useACMEHost = "nixos.cache.pandapip1.com";
        forceSSL = true;
        locations."/".proxyPass = "http://[::1]:16206";
        locations."/.well-known/".root = "/var/lib/acme/acme-challenge/";
      };
    };
  };
}
