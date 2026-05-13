{
  config,
  ...
}:

{  
  services = {
    atticd = {
      enable = true;
      settings = {
        listen = "127.0.0.1:16206";
        api-endpoint = "https://cache.nixos.pandapip1.com/";
        storage = {
          type = "s3";
          bucket = "a7310486287908d892e70d10";
          region = "us-east-005";
          endpoint = "https://s3.us-east-005.backblazeb2.com";
        };
        compression.type = "xz";
      };
      environmentFile = "/env/secrets/attic/.env";
    };
  };
  secrets.attic.ownership = {
    inherit (config.services.atticd) user group;
  };

  services.nginx = {
    virtualHosts = {
      "nixos.cache.pandapip1.com" = {
        useACMEHost = "cache.pandapip1.com";
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:16206";
      };
    };
  };
}
