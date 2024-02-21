{ config, lib, pkgs, nix-software-center, nixos-conf-editor, ... }:

{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

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

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Configure installed packages
  environment.systemPackages = with pkgs; [
    (ungoogled-chromium.overrideAttrs (old: {
      postInstall = ''
        wrapProgram $out/bin/chromium --extension-mime-request-handling=always-prompt-for-install
      '';
    }))
    thunderbird
    nextcloud-client
    keepassxc
    nix-software-center.packages.${system}.nix-software-center
    nixos-conf-editor.packages.${system}.nixos-conf-editor
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with vscode-extensions; [
        bbenoist.nix
        ms-python.python
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
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
    epiphany    # web browser
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

  # Configure chromium
  environment.etc."chromium/policies/managed/gnome_x11.json" = {
    text = ''
      {
        "ShowHomeButton": true,
        "DefaultSearchProviderEnabled": true,
        "DefaultSearchProviderName": "DuckDuckGo",
        "DefaultSearchProviderSearchURL": "https://duckduckgo.com/?q={searchTerms}&ie={inputEncoding}",
        "DefaultSearchProviderSuggestURL": "https://ac.duckduckgo.com/ac/?q={searchTerms}",
        "BlockExternalExtensions": true,
        "ExtensionInstallSources": [
          "https://clients2.google.com/*",
          "https://clients2.googleusercontent.com/*"
        ],
        "ExtensionInstallForcelist": [
          "ddkjiahejlhfcafbddmgiahcphecmpfh;https://clients2.google.com/service/update2/crx",
          "oboonakemofpalcgghocfoadofidjkkk;https://clients2.google.com/service/update2/crx",
          "nfcdcdoegfnidkeldipgmhbabmndlhbf;https://clients2.google.com/service/update2/crx",
          "mpbjkejclgfgadiemmefgebjfooflfhl;https://clients2.google.com/service/update2/crx",
          "icallnadddjmdinamnolclfjanhfoafe;https://clients2.google.com/service/update2/crx",
          "pfldomphmndnmmhhlbekfbafifkkpnbc;https://clients2.google.com/service/update2/crx",
          "nakplnnackehceedgkgkokbgbmfghain;https://clients2.google.com/service/update2/crx",
          "mhfjchmiaocbleapojmgnmjfcmanihio;https://clients2.google.com/service/update2/crx",
          "enamippconapkdmgfgjchkhakpfinmaj;https://clients2.google.com/service/update2/crx",
          "omkfmpieigblcllmkgbflkikinpkodlk;https://clients2.google.com/service/update2/crx",
          "gebbhagfogifgggkldgodflihgfeippi;https://clients2.google.com/service/update2/crx",
          "mnjggcdmjocbbbhaepdhchncahnbgone;https://clients2.google.com/service/update2/crx",
          "khncfooichmfjbepaaaebmommgaepoid;https://clients2.google.com/service/update2/crx"
        ]
      }
    '';
    mode = "0444";
  };
}
