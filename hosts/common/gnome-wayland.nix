{ config, lib, pkgs, nix-software-center, nixos-conf-editor, ... }:

{
  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.xserver = {
    enable = true;
    libinput.enable = true;
    layout = user.services.xserver.layout;
    xkbVariant = user.services.xserver.xkbVariant;
    displayManager = {
      defaultSession = "gnome-wayland";
      gdm = {
        enable = true;
        wayland = true;
      };
      gnome.enable = true;
    };
    excludePackages = with pkgs; [ xterm ];
  };
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true;
  };

  # Configure installed packages
  environment.systemPackages = with pkgs; [
    thunderbird
    nextcloud-client
    keepassxc
    nix-software-center.packages.${system}.nix-software-center
    nixos-conf-editor.packages.${system}.nixos-conf-editor
    gnomeExtensions.remove-alttab-delay-v2
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with vscode-extensions; [
        bbenoist.nix
        ms-python.python
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
        vscode-extensions.james-yu.latex-workshop
        github.vscode-pull-request-github
        github.vscode-github-actions
        github.copilot
        github.copilot-chat
        github.codespaces
        gitlab.gitlab-workflow
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "remote-ssh-edit";
          publisher = "ms-vscode-remote";
          version = "0.47.2";
          sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
        }
      ];
    })
  ];
  services.xserver.excludePackages = with pkgs; [
    xterm
  ];
  environment.gnome.excludePackages = with pkgs; with pkgs.gnome; [
    baobab      # disk usage analyzer
    cheese      # photo booth
    eog         # image viewer
    gedit       # text editor
    simple-scan # document scanner
    totem       # video player
    yelp        # help viewer
    evince      # document viewer
    file-roller # archive manager
    geary       # email client
    seahorse    # password manager

    gnome-calculator gnome-calendar gnome-characters gnome-clocks gnome-contacts
    gnome-font-viewer gnome-logs gnome-maps gnome-music gnome-screenshot
    gnome-system-monitor gnome-weather gnome-disk-utility
    gnome-connections gnome-photos gnome-text-editor gnome-tour
  ];

  # GNOME Extensions
  programs.dconf = {
    enable = true;
    profiles = {
      user.databases = [{
        settings = with lib.gvariant; {
          "org/gnome/shell".enabled-extensions = [
            "TEMP"
          ];
        };
      }];
    };
  };
}
