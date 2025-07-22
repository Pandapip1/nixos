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

  documentation = {
    enable = true;
    man = {
      enable = true;
      man-db.enable = false;
      mandoc.enable = false; # Broken on aarch64
      generateCaches = true;
    };
    doc.enable = true;
    dev.enable = true;
    info.enable = true;
    nixos = {
      enable = true;
      #includeAllModules = true;
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
    withNpmAndGcc = true;
    configFile = "${self}/config/nodered/settings.js";
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
      hostname = "keycloak.berry.pandapip1.com";
      http-host = "::1"; # We are using a reverse proxy
      http-enabled = true; # We are using a reverse proxy
      http-port = 7412; # Random number
      https-port = 7413; # Unused
    };
    database = {
      type = "postgresql";
      name = "keycloak";
      username = "keycloak";
      passwordFile = "/run/user/${toString config.users.users.keycloak.uid}/randomPassword";
      host = "localhost";
      port = config.services.postgresql.settings.port;
      createLocally = false;
    };
    # TODO: configure
  };
  # Currently just used for postgres auth
  # See https://github.com/NixOS/nixpkgs/issues/422823
  users.users.keycloak = {
    uid = 996;
    group = "nogroup";
    isSystemUser = true;
  };
  systemd.services.set-random-password-keycloak = {
    description = "Set random password for user keycloak";
    after = [ "systemd-user-sessions.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      User = "root";
      CapabilityBoundingSet = [
        "CAP_DAC_OVERRIDE"
        "CAP_CHOWN"
        "CAP_FOWNER"
      ];
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      PrivateTmp = true;
      ProtectProc = "invisible";
      NoNewPrivileges = true;
      BindReadOnlyPaths = [
        "/dev/urandom"
        "/etc/passwd"
      ];
      BindPaths = [
        "/etc/shadow"
        "/etc/shadow.lock"
        "/etc/passwd.lock"
        "/run/user"
      ];
    };
    script = ''
      set -euxo pipefail

      usermod="${lib.getExe' pkgs.shadow "usermod"}"
      openssl="${lib.getExe pkgs.openssl}"

      user="keycloak"
      uid="$(id -u "$user")"
      gid="$(id -g "$user")"

      pw=$(head -c 128 /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)

      hash=$("$openssl" passwd -6 "$pw")
      "$usermod" -p "$hash" "$user"

      mkdir -p "/run/user/$uid"
      chown "$uid:$gid" "/run/user/$uid"

      echo "$pw" > "/run/user/$uid/randomPassword"
      chmod 400 "/run/user/$uid/randomPassword"
      chown "$uid:$gid" "/run/user/$uid/randomPassword"
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
      add_header X-Frame-Options DENY;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;

      # This might create errors
      proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
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
