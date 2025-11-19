{
  self,
  ...
}:

{
  security.acme = {
    acceptTerms = true;
    defaults.email = "gavinnjohn@gmail.com";
    certs = {
      "cantaloupe.pandapip1.com" = {
        dnsProvider = "cloudflare";
        environmentFile = "/etc/secrets/acme/cloudflare-api-key";
        extraDomainNames = [ "*.cantaloupe.pandapip1.com" ];
      };
    };
  };

  secrets.nixbuild.acme.user = "acme";

  services.nginx = {
    enable = true;

    # Enable recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Only allow PFS-enabled ciphers with AES256
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    # HTTPS hardening
    appendHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
        https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;

      # Enable CSP for your services.
      #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin';

      # Disable embedding as a frame
      # Why is nginx like this? This is so stupid
      map $server_name $x_frame_options {
        default "DENY";
        # keycloak.berry.pandapip1.com "SAMEORIGIN";
      }
      add_header X-Frame-Options $x_frame_options;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;

      # Set cookie security
      proxy_cookie_flags ~ KEYCLOAK_SESSION Secure SameSite=None;
      proxy_cookie_flags ~ KEYCLOAK_IDENTITY Secure SameSite=None;
    '';

    virtualHosts = {
      "cantaloupe.pandapip1.com" = {
        useACMEHost = "cantaloupe.pandapip1.com";
        forceSSL = true;
        root = ./config/static/cantaloupe.pandapip1.com;
      };
    };
  };

  # Open port 80 and 443
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # Allow nginx user to see ACME certs
  # "Certificate berry.pandapip1.com (group=acme) must be readable by service(s) nginx.service (user=nginx groups=nginx), nginx-config-reload.service (user=root groups=)"
  users.users.nginx.extraGroups = [ "acme" ];
}
