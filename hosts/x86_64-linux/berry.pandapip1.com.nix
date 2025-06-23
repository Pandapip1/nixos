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

  # We're legacy BIOS
  ec2.efi = false;

  # Fix: Add ssm-user to wheel to stop:
  # Some definitions in `security.sudo.extraRules` refer to users other than 'root' or groups other than 'wheel'. Disable `config.security.sudo.execWheelOnly`, or adjust the rules.
  users.users.ssm-user.extraGroups = [ "wheel" ];

  documentation = {
    enable = true;
    man = {
      enable = true;
      man-db.enable = false;
      mandoc.enable = true; # BSD-compatible
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


  # Get key for berry.pandapip1.com
  security.acme = {
    acceptTerms = true;
    defaults.email = "gavinnjohn@gmail.com";
    certs."berry.pandapip1.com" = {
      dnsProvider = "cloudflare";
      credentialsFile = "/etc/secrets/cloudflare";
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
        proxyPass = "http://127.0.0.1:${toString config.services.node-red.port}";
        proxyWebsockets = true;
      };
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
