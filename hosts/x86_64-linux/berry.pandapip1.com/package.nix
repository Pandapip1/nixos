{
  lib,
  self,
  config,
  pkgs,
  modulesPath,
  ...
}:

{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 16;
    };
    efi.canTouchEfiVariables = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/BERRY_ROOT";
      fsType = "btrfs";
    };
    "/boot" = {
      device = "/dev/disk/by-label/BERRY_BOOT";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };
  swapDevices = [
    {
      device = "/dev/disk/by-label/swap";
    }
  ];

  networking = {
    useDHCP = false;
    interfaces.eno1 = {
      ipv4.addresses = [
        {
          address = "23.94.10.178";
          prefixLength = 30;
        }
      ];
    };
    defaultGateway = {
      address = "23.94.10.177";
      interface = "eno1";
    };
  };

  services.openssh = {
    enable = true;
  };

  # Get key for berry.pandapip1.com
  security.acme = {
    acceptTerms = true;
    defaults.email = "gavinnjohn@gmail.com";
  };

  # OpenBao for central management of APIs
  services.openbao = {
    # enable = true;
    # TODO: configure
  };

  # Keycloak for IAM
  services.keycloak = {
    enable = true;
    settings = {
      hostname = "https://keycloak.berry.pandapip1.com";
      proxy-headers = "xforwarded"; # We are using a reverse proxy
      http-host = "::1"; # We are using a reverse proxy
      http-enabled = true; # We are using a reverse proxy
      http-port = 7412; # Random number
    };
    database = {
      type = "postgresql";
      name = "keycloak";
      username = "keycloak";
      passwordFile = "/run/pg-password-keycloak/pg-keycloak-pw";
      host = "localhost";
      port = config.services.postgresql.settings.port;
      createLocally = false;
    };
    # TODO: configure
  };
  systemd.services.keycloak.requires = [ "set-random-pg-password-keycloak.service" ];
  # Currently just used for postgres auth
  # See https://github.com/NixOS/nixpkgs/issues/422823
  users.users.keycloak = {
    isSystemUser = true;
    group = "keycloak";
  };
  users.groups.keycloak = { };
  systemd.services.set-random-pg-password-keycloak =
    let
      db = "keycloak";
      user = "keycloak";
    in
    {
      description = "Set random ${db} password for PostgreSQL";
      after = [ "postgresql.service" "postgresql-refresh-collation.service" ];
      requires = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ postgresql ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectoryPreserve = "yes";
        User = user;
        RuntimeDirectory = "pg-password-${db}";
      };

      script = ''
        set -euxo pipefail

        if ! psql -d keycloak -v ON_ERROR_STOP=1 -tAc "SELECT 1 FROM pg_database WHERE datname = '${db}'" | grep -q 1; then
          psql -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE ${db} OWNER ${user};"
        fi

        pw=$(head -c 128 /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)

        psql -v ON_ERROR_STOP=1 -c "ALTER USER ${user} WITH PASSWORD '$pw';"

        if [ -f /run/pg-password-${db}/pg-${user}-pw ]; then
          chmod 600 /run/pg-password-${db}/pg-${user}-pw
        fi
        echo "$pw" > /run/pg-password-${db}/pg-keycloak-pw
        chmod 400 /run/pg-password-${db}/pg-${user}-pw
      '';
    };

  # Postgres for Keycloak and other data needed by berry's various services
  # TODO: Add config.services.postgresql.user and config.services.postgresql.group to set those in particular
  # The default user and group are postgres
  services.postgresql = {
    enable = true;
    enableTCPIP = true; # Required by keycloak, TODO consider making upstream patch to support socket
    authentication = ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      host    all             all             127.0.0.1/32            scram-sha-256
      host    all             all             ::1/128                 scram-sha-256
    '';
    settings.password_encryption = "scram-sha-256";
    ensureDatabases = [
      config.services.keycloak.database.name
    ];
    ensureUsers = [
      {
        name = config.services.keycloak.database.username;
        ensureClauses.superuser = true; # During initial setup, we def want the keycloak user to be superuser
        # TODO: Once setup done, superuser = false
      }
      {
        name = config.services.redmine.user;
        ensureClauses.superuser = true; # During initial setup, we def want the keycloak user to be superuser
        # TODO: Once setup done, superuser = false
      }
    ];
    # TODO: Set up initialScript?
  };

  # Nginx for proxying
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
        keycloak.berry.pandapip1.com "SAMEORIGIN";
      }
      add_header X-Frame-Options $x_frame_options;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;

      # Set cookie security
      proxy_cookie_flags ~ KEYCLOAK_SESSION Secure SameSite=None;
      proxy_cookie_flags ~ KEYCLOAK_IDENTITY Secure SameSite=None;
    '';

    virtualHosts = {
      "berry.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        root = ./config/static/berry.pandapip1.com;
      };
      "keycloak.berry.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.keycloak.settings.http-port}";
          proxyWebsockets = true;
        };
      };
      "redmine.berry.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.redmine.port}";
          proxyWebsockets = true;
        };
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

  # Enable nebula network
  services.nebula.networks.nebula0.enable = true;

  # Redmine
  services.redmine = {
    enable = true;

    port = 3944;
    address = "::1";

    database = {
      type = "postgresql";
      host = "localhost";
      port = config.services.postgresql.settings.port;
      name = "redmine";
      user = "redmine";
      passwordFile = "/run/pg-password-redmine/pg-redmine-pw";
      createLocally = false;
    };

    components = {
      git = true;
    };

    plugins = {
      redmine_oauth = pkgs.fetchFromGitHub {
        owner = "kontron";
        repo = "redmine_oauth";
        tag = "v4.2.3";
        hash = "sha256-J1VF3ZQIiHVJsJ2wfYrHE1A6g8sb/Iz5rIot1g9QzqY=";
      };
    };
  };
  systemd.services.postgresql-refresh-collation = {
    description = "Refresh PostgreSQL collation versions";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
    };

    script = ''
      set -euo pipefail

      databases=$(psql -d postgres -tAc "SELECT datname FROM pg_database WHERE datallowconn AND NOT datistemplate")

      for db in template1 postgres $databases; do
        echo "Processing $db..."
        psql -d "$db" -v ON_ERROR_STOP=1 -c "REINDEX DATABASE \"$db\";"
        psql -d postgres -v ON_ERROR_STOP=1 -c "ALTER DATABASE \"$db\" REFRESH COLLATION VERSION;"
      done
    '';
  };
  systemd.services.set-random-pg-password-redmine =
    let
      db = config.services.redmine.database.name;
      inherit (config.services.redmine) user;
    in
    {
      description = "Set random ${db} password for PostgreSQL";
      after = [ "postgresql.service" "postgresql-refresh-collation.service" ];
      requires = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ postgresql ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectoryPreserve = "yes";
        User = user;
        RuntimeDirectory = "pg-password-${db}";
      };

      script = ''
        set -euxo pipefail

        if ! psql -d keycloak -v ON_ERROR_STOP=1 -tAc "SELECT 1 FROM pg_database WHERE datname = '${db}'" | grep -q 1; then
          psql -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE ${db} OWNER ${user};"
        fi

        pw=$(head -c 128 /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)

        psql -v ON_ERROR_STOP=1 -c "ALTER USER ${user} WITH PASSWORD '$pw';"

        if [ -f /run/pg-password-${db}/pg-${user}-pw ]; then
          chmod 600 /run/pg-password-${db}/pg-${user}-pw
        fi
        echo "$pw" > /run/pg-password-${db}/pg-keycloak-pw
        chmod 400 /run/pg-password-${db}/pg-${user}-pw
      '';
    };
  systemd.services.redmine.requires = [ "set-random-pg-password-keycloak.service" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
