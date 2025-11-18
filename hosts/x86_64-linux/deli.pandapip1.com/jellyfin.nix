{
  services = {
    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    nginx.virtualHosts = {
      "jellyfin.deli.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:8096"; # Default jellyfin port
          proxyWebsockets = true;
        };
      };
    };
  };
}
