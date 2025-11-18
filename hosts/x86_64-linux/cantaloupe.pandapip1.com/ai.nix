{
  services = {
    open-webui = {
      enable = true;
      host = "[::]";
      port = 7890; # Just a random free port
      openFirewall = true;
      environment = {
        WEBUI_URL = "http://cantaloupe.local:7890";
        ENABLE_LOGIN_FORM = "false";
        ENABLE_OAUTH_SIGNUP = "true";
        ENABLE_OAUTH_GROUP_MANAGEMENT = "true";
        ENABLE_OAUTH_GROUP_CREATION = "true";
        OAUTH_GROUP_CLAIM = "groups";
        OAUTH_CLIENT_ID = "cantaloupe-open-webui";
        OAUTH_CLIENT_SECRET = "ruu00mwn0x1tCzZWukSRjJuRj3zwiWZd"; # TODO: Find a way to avoid publicly sharing the secret; this should be fine as it doesn't have a service account
        OPENID_PROVIDER_URL = "https://keycloak.berry.pandapip1.com/realms/pandaport/.well-known/openid-configuration";
        OAUTH_PROVIDER_NAME = "PandaPort";
        OAUTH_SCOPES = "openid email profile groups";
      };
    };
    ollama = {
      enable = true;
      host = "[::]";
      openFirewall = true; # Make ollama accessible across network
      # Default port is acceptable
      loadModels = [
        "deepseek-r1"
        "gemma3n"
        "llama2-uncensored"

        # For Continue
        "nomic-embed-text:latest"
        "llama3.1:8b"
        "qwen2.5-coder:1.5b-base"
      ];
      acceleration = "rocm";
      rocmOverrideGfx = "9.0.6"; # gfx906 (Instinct MI50)
    };
    nginx.virtualHosts = {
      "open-webui.cantaloupe.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.open-webui.port}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
