{ lib, config, pkgs, nixpkgs, hostname, comma, system, ... }:

{
  nix = {
    settings = {
      trusted-substituters = [
        "https://nixos-search.cachix.org"
        "https://cosmic.cachix.org/"
        "https://hydra.nixos.org/"
      ];
      trusted-public-keys = [
        "nixos-search.cachix.org-1:1HV3YF8az4fywnH+pAd+CXFEdpTXtv9WpoivPi+H70o="
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
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
    };
    nixPath = lib.mkForce [ "nixpkgs=${nixpkgs.outPath}" ];
    channel.enable = false;
    package = pkgs.nixVersions.latest;
  };

  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 16;
      };
      efi.canTouchEfiVariables = true;
    };
    initrd.systemd.enable = true;
    tmp.cleanOnBoot = true;
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Install comma command-not-found
  programs.bash.interactiveShellInit = ''
    source ${comma.packages."${system}".comma}/etc/profile.d/command-not-found.sh
  '';

  programs.zsh.interactiveShellInit = ''
    source ${comma.packages."${system}".comma}/etc/profile.d/command-not-found.sh
  '';

  # See https://github.com/bennofs/nix-index/issues/126
  programs.fish.interactiveShellInit = let
    wrapper = pkgs.writeScript "command-not-found" ''
      #!${lib.getExe pkgs.bash}
      source ${comma.packages."${system}".comma}/etc/profile.d/command-not-found.sh
      command_not_found_handle "$@"
    '';
  in ''
    function __fish_command_not_found_handler --on-event fish_command_not_found
        ${wrapper} $argv
    end
  '';

  # Auto nix-index
  programs.nix-index = {
    enable = true;
    enableZshIntegration = false;
    enableFishIntegration = false;
    enableBashIntegration = false;
  };
  programs.command-not-found.enable = false;
  systemd.services.nix-index = {
    description = "Nix Indexer";
    script = ''
      mkdir -p /var/cache/nix-index/
      umask 022
      ${lib.getExe' pkgs.nix-index "nix-index"}
    '';
    environment = {
      NIX_INDEX_DATABASE = "/var/cache/nix-index/";
      NIX_PATH = "nixpkgs=flake:nixpkgs:${lib.escapeShellArg nixpkgs.outPath}";
    };
    serviceConfig.Type = "oneshot";
    startAt = "daily";
  };
  systemd.timers.nix-index = {
    timerConfig = {
      Persistent = true;
    };
  };
  environment.variables = {
    NIX_INDEX_DATABASE = "/var/cache/nix-index/";
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
  systemd.timers.nix-gc = lib.mkForce {
    timerConfig = {
      Persistent = true;
    };
  };

  hardware.enableAllFirmware = true;

  time.timeZone = lib.mkForce null;
  location.provider = "geoclue2";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    firewall.enable = true;
    nftables.enable = true;
  };

  environment.systemPackages = (with pkgs; [
    git
    gnupg
    vim
    adwaita-icon-theme-legacy
  ]) ++ [ comma.packages."${system}".comma ];

  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    sharedModules = [
      {
        home.stateVersion = "23.11";
      }
    ];
  };

  services.pcscd.enable = true;
  
  hardware.mcelog.enable = true;
  hardware.gpgSmartcards.enable = true;
  hardware.bluetooth.enable = true;
  hardware.trackpoint.enable = true;
  hardware.pulseaudio.enable = false; # Use pipewire instead
  hardware.flipperzero.enable = true;
  hardware.usb-modeswitch.enable = true;

  services.hardware.bolt.enable = true;

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.udev = {
    enable = true;
    packages = with pkgs; [
      xr-hardware
      android-udev-rules
    ];
  };

  fonts = {
    fontDir.enable = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "Noto Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      nerdfonts
    ];
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  programs.starship.enable = true;

  # nix-ld
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # TODO: Remove when Caltech placement exam done
    xorg.libXext
    xorg.libX11
    xorg.libXrender
    xorg.libXtst
    xorg.libXi
    fontconfig
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
