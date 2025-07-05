{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.nixbuild-net;
in
{
  options = {
    nixbuild-net = {
      enable = lib.mkEnableOption "nixbuild.net";
      crossOnly = lib.mkEnableOption "nixbuild for only cross compiling";
      identity = {
        string = lib.mkOption {
          description = "The identity string";
          default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM"; # TODO make generic
        };
        key = lib.mkOption {
          description = "The location of the SSH identity file";
          default = "/etc/secrets/nixbuild/id_nixbuild-net";
        };
      };
      publicKey = lib.mkOption {
        description = "The nixbuild.net trusted public key for your account";
        default = "nixbuild.net/WD7ZMS-1:fDoljU8vNe12BOadKcF0jxTvRddZjIjUkoyZCm7QMFw=";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh.extraConfig = ''
      Host eu.nixbuild.net
      PubkeyAcceptedKeyTypes ssh-ed25519
      ServerAliveInterval 60
      IPQoS throughput
      IdentityFile ${cfg.identity.key}
    '';

    programs.ssh.knownHosts = {
      nixbuild = {
        hostNames = [ "eu.nixbuild.net" ];
        publicKey = cfg.identity.string;
      };
    };

    nix = {
      distributedBuilds = lib.mkDefault true;
      settings = lib.mkIf (!cfg.crossOnly) {
        trusted-substituters = [ "ssh://eu.nixbuild.net" ];
        trusted-public-keys = [ cfg.publicKey ];
      };
      buildMachines =
        lib.map
          (system: {
            hostName = "eu.nixbuild.net";
            sshUser = "root";
            sshKey = cfg.identity.key;
            inherit system;
            supportedFeatures = [
              "nixos-test"
              "big-parallel"
              "kvm"
            ];
          })
          (
            lib.filter (system: (config.nixpkgs.hostPlatform != system || (!cfg.crossOnly))) [
              "x86_64-linux"
              "x86_64-darwin"
              "aarch64-linux"
              "aarch64-darwin"
            ]
          );
    };
  };
}
