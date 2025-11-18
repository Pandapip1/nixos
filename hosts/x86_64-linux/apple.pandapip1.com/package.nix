{
  lib,
  pkgs,
  nixos-hardware,
  ...
}:

{
  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-t480s
  ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 16;
    };
    efi.canTouchEfiVariables = true;
  };

  # Use COSMIC DE
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  services.gnome.gnome-keyring.enable = false; # For some reason enabling cosmic enables gnome keyring. I want to use keepassxc thank you very much.

  # Enable nixbuild.net, but only for building to other systems
  nixbuild-net = {
    # enable = true;
    crossOnly = true;
  };

  services.nebula.networks.nebula0.enable = true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems = {
    "/" = {
      fsType = "btrfs";
      device = "/dev/disk/by-label/NIXROOT";
      options = [
        "subvol=@"
        "compress=lzo"
        "noatime"
      ];
    };
    "/boot" = {
      fsType = "vfat";
      device = "/dev/disk/by-label/NIXBOOT";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/swap";
    }
  ];

  programs.qgroundcontrol.enable = true;

  environment.systemPackages = with pkgs; [
    texliveFull
    act
    nrfconnect
    # TODO: Make and upstream proper packaging
    (writeScriptBin "smolslimeconfigurator" ''
      ${lib.getExe (python3.withPackages (pythonPackages: with pythonPackages; [
        customtkinter
        pyserial
        requests
        tkinter
      ]))} ${fetchFromGitHub {
        owner = "ICantMakeThings";
        repo = "SmolSlimeConfigurator";
        tag = "Release-V7";
        hash = "sha256-gGh1IF0lpm9tX1a2ZjH0QgeCFR2NuNkx7C9UnVaIg74=";
      }}/SmolSlimeConfiguratorV7.py $@
    '')
  ];

  # Undervolt (tested stable using stress-ng --<cpu 8/gpu 32> --verify --timeout 5s at both battery saver and performance power modes)
  services.undervolt = {
    enable = true;
    coreOffset = -80;
    uncoreOffset = -20;
    gpuOffset = -50;
    analogioOffset = 0;
  };

  services.autoaspm.enable = lib.mkForce false; # Causes issues on my t480s

  # Needed for dabney internal net
  services.tailscale.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
