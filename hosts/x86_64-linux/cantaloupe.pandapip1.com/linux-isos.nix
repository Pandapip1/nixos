{
  services = {
    lidarr = {
      enable = true;
    };
    radarr = {
      enable = true;
    };
    readarr = {
      enable = true;
    };
    sonarr = {
      enable = true;
    };
    whisparr = {
      enable = true;
    };
    prowlarr = {
      enable = true
    };
    jellyseerr = {
      enable = true;
    };
    bazarr = {
      enable = true;
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
      "lidarr.cantaloupe.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.lidarr.settings.server.port}";
          proxyWebsockets = true;
        };
      };
      "radarr.cantaloupe.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.radarr.settings.server.port}";
          proxyWebsockets = true;
        };
      };
      "readarr.cantaloupe.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.readarr.settings.server.port}";
          proxyWebsockets = true;
        };
      };
      "sonarr.cantaloupe.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.sonarr.settings.server.port}";
          proxyWebsockets = true;
        };
      };
      "whisparr.cantaloupe.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.whisparr.settings.server.port}";
          proxyWebsockets = true;
        };
      };
      "prowlarr.cantaloupe.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.prowlarr.settings.server.port}";
          proxyWebsockets = true;
        };
      };
      "jellyseerr.cantaloupe.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.jellyseerr.port}";
          proxyWebsockets = true;
        };
      };
      "bazarr.cantaloupe.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.bazarr.listenPort}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
