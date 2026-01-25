{
  services = {
    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    nginx.virtualHosts = {
      "jellyfin.cantaloupe.pandapip1.com" = {
        useACMEHost = "cantaloupe.pandapip1.com";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:8096"; # Default jellyfin port
          proxyWebsockets = true;
        };
      };
    };
  };
}
