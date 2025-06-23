
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.nixbuild-net;

in {
  options = {
    nixbuild-net = {
      enable = lib.mkEnableOption "nixbuild.net";
    };
  };

  config = mkIf cfg.enable {
    {
      programs.ssh.extraConfig = ''
        Host eu.nixbuild.net
        PubkeyAcceptedKeyTypes ssh-ed25519
        ServerAliveInterval 60
        IPQoS throughput
        IdentityFile /etc/secrets/id_nixbuild-net
      '';

      programs.ssh.knownHosts = {
        nixbuild = {
          hostNames = [ "eu.nixbuild.net" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
        };
      };

      nix = {
        distributedBuilds = true;
        buildMachines = [
          { hostName = "eu.nixbuild.net";
            system = "x86_64-linux";
            maxJobs = 100;
            supportedFeatures = [ "benchmark" "big-parallel" ];
          }
        ];
      };
    }
  };
}
