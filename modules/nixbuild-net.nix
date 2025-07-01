{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.nixbuild-net;
in
{
  options = {
    nixbuild-net = {
      enable = lib.mkEnableOption "nixbuild.net";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh.extraConfig = ''
      Host eu.nixbuild.net
      PubkeyAcceptedKeyTypes ssh-ed25519
      ServerAliveInterval 60
      IPQoS throughput
      IdentityFile /etc/secrets/nixbuild/id_nixbuild-net
    '';

    programs.ssh.knownHosts = {
      nixbuild = {
        hostNames = [ "eu.nixbuild.net" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
      };
    };

    nix = {
      distributedBuilds = true;
      settings = {
        trusted-substituters = [
          "ssh://eu.nixbuild.net"
        ];
        trusted-public-keys = [
          "nixbuild.net/WD7ZMS-1:fDoljU8vNe12BOadKcF0jxTvRddZjIjUkoyZCm7QMFw="
        ];
      };
    };
  };
}
