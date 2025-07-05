{
  lib,
  config,
  pkgs,
  srvos,
  modulesPath,
  ...
}:

{
  imports = [
    srvos.nixosModules.server
    srvos.nixosModules.hardware-amazon
    # Users
    ../../users/gavin.nix
    # Services
    ../../services/nebula.nix
  ];

  # Max jobs 2; use a single core for each of them
  # Availability more important than build speed, but 2 jobs is a 100% speedup so worth it
  nix.settings = {
    max-jobs = 2;
    cores = 1;
  };

  # Simply not necessary
  hardware.enableAllFirmware = false;

  ec2.efi = true;

  # Berry is underpowered, use external builder
  nixbuild-net.enable = true;

  # Some definitions in `security.sudo.extraRules` refer to users other than 'root' or groups other than 'wheel'. Disable `config.security.sudo.execWheelOnly`, or adjust the rules.
  # https://github.com/nix-community/srvos/issues/655
  security.sudo.execWheelOnly = lib.mkForce false;

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

  # Enable fail2ban for security
  services.fail2ban.enable = true;

  # Get key for berry.pandapip1.com
  security.acme = {
    acceptTerms = true;
    defaults.email = "gavinnjohn@gmail.com";
    certs."berry.pandapip1.com" = {
      dnsProvider = "cloudflare";
      credentialsFile = "/etc/secrets/cloudflare/cloudflare.ini";
      domain = "berry.pandapip1.com";
    };
  };

  services.node-red = {
    enable = true;
    openFirewall = false; # Do NOT expose node-red
    withNpmAndGcc = true;
    configFile = ../../config/nodered/settings.js;
  };

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

    virtualHosts."berry.pandapip1.com" = {
      useACMEHost = "berry.pandapip1.com";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString config.services.node-red.port}";
        proxyWebsockets = true;
      };
    };
  };
  # Open port 80 and 443
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.inadyn = {
    enable = true;
    # TODO: make declarative
    configFile = "/etc/secrets/inadyn/inadyn.conf";
  };
  secrets.inadyn.ownership = {
    inherit (config.services.inadyn) user group;
  };

  # Allow nginx user to see ACME certs
  # "Certificate berry.pandapip1.com (group=acme) must be readable by service(s) nginx.service (user=nginx groups=nginx), nginx-config-reload.service (user=root groups=)"
  users.users.nginx.extraGroups = [ "acme" ];

  # Makes berry even slower but we're disk constrained so it makes sense to
  nix.settings.auto-optimise-store = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
