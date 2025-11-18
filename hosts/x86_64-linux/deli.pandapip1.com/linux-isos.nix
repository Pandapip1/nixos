{
  config,
  ...
}:

{
  services = {
    lidarr = {
      enable = true;
      openFirewall = true;
    };
    radarr = {
      enable = true;
      openFirewall = true;
    };
    readarr = {
      enable = true;
      openFirewall = true;
    };
    sonarr = {
      enable = true;
      openFirewall = true;
    };
    whisparr = {
      enable = true;
      openFirewall = true;
    };
    prowlarr = {
      enable = true;
      openFirewall = true;
    };
    jellyseerr = {
      enable = true;
      openFirewall = true;
    };
    bazarr = {
      enable = true;
      openFirewall = true;
    };
    recyclarr = {
      enable = true;
      configuration = {
        radarr = [
          {
            api_key._secret = "/etc/secrets/recyclarr/apikeys/radarr";
            base_url = "http://localhost:${toString config.services.radarr.settings.server.port}";
            instance_name = "main";
          }
        ];
        sonarr = [
          {
            api_key._secret = "/etc/secrets/recyclarr/apikeys/sonarr";
            base_url = "http://localhost:${toString config.services.sonarr.settings.server.port}";
            instance_name = "main";
          }
        ];
      };
    };
    nginx.virtualHosts = {
      "lidarr.deli.pandapip1.com" = {
        useACMEHost = "deli.pandapip1.com";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.lidarr.settings.server.port}";
          proxyWebsockets = true;
        };
      };
      "radarr.deli.pandapip1.com" = {
        useACMEHost = "deli.pandapip1.com";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.radarr.settings.server.port}";
          proxyWebsockets = true;
        };
      };
      "readarr.deli.pandapip1.com" = {
        useACMEHost = "deli.pandapip1.com";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.readarr.settings.server.port}";
          proxyWebsockets = true;
        };
      };
      "sonarr.deli.pandapip1.com" = {
        useACMEHost = "deli.pandapip1.com";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.sonarr.settings.server.port}";
          proxyWebsockets = true;
        };
      };
      "whisparr.deli.pandapip1.com" = {
        useACMEHost = "deli.pandapip1.com";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.whisparr.settings.server.port}";
          proxyWebsockets = true;
        };
      };
      "prowlarr.deli.pandapip1.com" = {
        useACMEHost = "deli.pandapip1.com";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.prowlarr.settings.server.port}";
          proxyWebsockets = true;
        };
      };
      "jellyseerr.deli.pandapip1.com" = {
        useACMEHost = "deli.pandapip1.com";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.jellyseerr.port}";
          proxyWebsockets = true;
        };
      };
      "bazarr.deli.pandapip1.com" = {
        useACMEHost = "deli.pandapip1.com";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.bazarr.listenPort}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
