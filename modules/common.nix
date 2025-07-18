{ lib, config, pkgs, nixpkgs, srvos, ... }:

{
  imports = [
    srvos.nixosModules.common
  ];

  nix = {
    settings = {
      trusted-substituters = [
        "https://nixos-search.cachix.org"
        "https://hydra.nixos.org/"
      ];
      trusted-public-keys = [
        "nixos-search.cachix.org-1:1HV3YF8az4fywnH+pAd+CXFEdpTXtv9WpoivPi+H70o="
        "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
      ];
      trusted-users = [
        "@wheel"
      ];
      experimental-features = [ "nix-command" "flakes" ];
    };
    registry = {
      nixpkgs.to = {
        type = "path";
        path = pkgs.path;
        narHash = builtins.readFile
            (pkgs.runCommandLocal "get-nixpkgs-hash"
              { nativeBuildInputs = [ pkgs.nix ]; }
              "nix-hash --type sha256 --sri ${pkgs.path} > $out");
      };
      # TODO: Add nixos-config for nixos-option command
    };
    nixPath = lib.mkForce [ "nixpkgs=${nixpkgs.outPath}" ];
    channel.enable = false;
    package = pkgs.nixVersions.latest;
  };

  nixpkgs.config = {
    allowUnfree = true;
    warnUndeclaredOptions = true;
    # WARNING: Below options cause mass rebuilds
    # cudaSupport = lib.mkDefault true;
    # rocmSupport = lib.mkDefault true;
  };

  documentation = {
    enable = lib.mkDefault true;
    man = {
      enable = lib.mkDefault true;
      man-db.enable = lib.mkDefault false;
      mandoc.enable = lib.mkDefault true; # BSD-compatible
      generateCaches = lib.mkDefault true;
    };
    doc.enable = lib.mkDefault true;
    dev.enable = lib.mkDefault true;
    info.enable = lib.mkDefault true;
    nixos = {
      enable = lib.mkDefault true;
      #includeAllModules = lib.mkDefault true;
    };
  };

  boot = {
    initrd.systemd.enable = true;
    tmp.cleanOnBoot = true;
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Auto nix-index
  programs.nix-index = {
    enable = true;
  };

  # Auto GC every day
  systemd.services.nix-gc = let
    configurationLimit = 16;
  in lib.mkForce {
    description = "Nix Garbage Collector";
    script = ''
      ${lib.getExe' pkgs.nix "nix-env"} --delete-generations +${toString configurationLimit} --profile /nix/var/nix/profiles/system
      exec ${lib.getExe' pkgs.nix "nix-collect-garbage"}
    '';
    serviceConfig.Type = "oneshot";
    startAt = "daily";
  };
  systemd.timers.nix-gc.timerConfig.Persistent = lib.mkForce true;

  hardware.enableAllFirmware = lib.mkDefault true;

  i18n = {
    supportedLocales = [ "all" ];
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_COLLATE = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_MESSAGES = "en_US.UTF-8";
      LC_MEASUREMENT = "en_GB.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_GB.UTF-8";
    };
  };

  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
    nftables.enable = true;
  };

  programs.comma = {
    enable = true;
    package = pkgs.comma-with-db;
  };

  # Local hosts blocklist
  networking.stevenBlackHosts = {
    enable = true;
  };

  security.rtkit.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = config.nixpkgs.hostPlatform == "x86_64-linux";
  };
  
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.udev.enable = true;

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  programs.starship = {
    enable = true;
    presets = [ "nerd-font-symbols" ];
    settings = {
      command_timeout = 2000;
    };
  };

  # DNS / mDNS
  services.resolved = {
    enable = true;
  };
  services.avahi = {
    enable = true;
    nssmdns4 = false; # Handled by systemd-resolved
    nssmdns6 = false; # Handled by systemd-resolved
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  # Use Adwaita theme
  # qt = {
  #   enable = true;
  #   platformTheme = "gnome";
  #   style = "adwaita-dark";
  # };

  # Renice daemon so that KDE plasma can stop freaking freezing
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # Provides debug symbols for troubleshooting purposes
  services.nixseparatedebuginfod.enable = true;
}
