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

  # We're using SSH keys, so NOPASSWD is needed
  security.sudo.wheelNeedsPassword = lib.mkForce false;

  networking = {
    useDHCP = false;
    interfaces.eno1 = {
      ipv4.addresses = [{
        address = "23.94.10.178";
        prefixLength = 30;
      }];
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

  # Nodered for workflow orchestration
  services.node-red = {
    enable = true;
    openFirewall = false; # Do NOT expose node-red
    configFile = "${self}/config/nodered/settings.js";
  };
  programs.nix-ld.enable = true;
  systemd.services.node-red = {
    environment = {
      NODE_PATH = pkgs.stdenvNoCC.mkDerivation {
        name = "node-red-settings-deps";

        src = pkgs.writeTextDir "package.json" ''
          {
            "name": "settings-js-deps",
            "version": "1.0.0",
            "private": true,
            "dependencies": {
              "passport-keycloak-oauth2-oidc-portable": "~2.6.1",
              "node-red-contrib-credentials": "~0.2.3",
              "node-red-contrib-oauth2": "~6.2.1",
              "node-red-contrib-chronos": "~1.29.2",
              "node-red-contrib-cron-plus": "~2.2.4",
              "node-red-contrib-postgresql": "~0.15.4",
              "node-red-contrib-axios": "~1.6.0",
              "node-red-contrib-calc": "~1.0.6"
            }
          }
        '';

        nativeBuildInputs = with pkgs; [
          jq
          moreutils
          nodejs
          nodePackages.npm
        ];

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          set -x
          export HOME=$(mktemp -d)
          export NODE_EXTRA_CA_CERTS=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
          mkdir -p $out
          npm config set cache $HOME/.npm
          npm install --ignore-scripts --no-audit --legacy-peer-deps --verbose
          cp -r node_modules/. $out/

          runHook postInstall
        '';

        # Work around https://github.com/brakmic/passport-keycloak-oauth2-oidc-portable/issues/5
        postFixup = ''
          ln -s $out/passport-keycloak-oauth2-oidc-portable/lib/cjs $out/passport-keycloak-oauth2-oidc-portable/cjs
          jq 'del(.type)' $out/passport-keycloak-oauth2-oidc-portable/package.json | sponge $out/passport-keycloak-oauth2-oidc-portable/package.json
        '';

        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = lib.fakeHash;
      };
    };
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
      passwordFile = "/run/pg-passwords/pg-keycloak-pw";
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
  users.groups.keycloak = {};
  systemd.services.set-random-pg-password-keycloak = {
    description = "Set random keycloak password for PostgreSQL";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectoryPreserve = "yes";
      User = "keycloak";
      RuntimeDirectory = "pg-passwords";
    };

    script = ''
      set -euxo pipefail

      psql=${lib.getExe' pkgs.postgresql "psql"}

      pw=$(head -c 128 /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)

      echo "$pw" > /run/pg-passwords/pg-keycloak-pw
      chmod 400 /run/pg-passwords/pg-keycloak-pw

      $psql -v ON_ERROR_STOP=1 -c "ALTER USER keycloak WITH PASSWORD '$pw';"
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
        root = "${self}/config/static/berry.pandapip1.com";
      };
      "node-red.berry.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.node-red.port}";
          proxyWebsockets = true;
        };
      };
      "keycloak.berry.pandapip1.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.keycloak.settings.http-port}";
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
