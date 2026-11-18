{
  config,
  lib,
  ...
}:

# SSH keys from the OpenPGP web of trust; see
# modules/common/security/gpg-authorized-keys.nix.
let
  cfg = config.gpgAuthorizedKeys;
  update = "${cfg.updateScript}/bin/gpg-authorized-keys-update";
  commandUser = "gpg-authorized-keys";
  # sshd only runs an AuthorizedKeysCommand that is root-owned with no
  # group- or world-writable directory above it; /nix/store is group-writable
  # (nixbld), so the command is copied into /etc.
  commandPath = "/etc/ssh/gpg-authorized-keys-command";
in
{
  config = lib.mkMerge [
    {
      gpgAuthorizedKeys.stateDir = "/var/lib/gpg-authorized-keys";

      # Defined whether or not it is used: users.users decides whether it is
      # (gpgAuthorizedKeys.enable), so it can't depend on that.
      users.users.${commandUser} = {
        isSystemUser = true;
        group = commandUser;
        description = "sshd AuthorizedKeysCommand (OpenPGP keys)";
      };
      users.groups.${commandUser} = { };
    }

    (lib.mkIf (cfg.enable && config.services.openssh.enable) {
      environment.etc."ssh/gpg-authorized-keys-command" = {
        source = cfg.commandScript { };
        mode = "0555";
      };

      services.openssh = {
        authorizedKeysCommand = "${commandPath} %u";
        authorizedKeysCommandUser = commandUser;
      };

      # Offline (seed keys and the keyring already here), so activation never
      # waits on the network; the timer fetches from the keyserver.
      system.activationScripts.gpgAuthorizedKeys = {
        deps = [ "users" ];
        text = ''
          ${update} --offline || echo "gpg-authorized-keys: refresh failed; see above" >&2
        '';
      };

      systemd.services.gpg-authorized-keys = {
        description = "Refresh SSH keys from the OpenPGP web of trust";
        wants = [ "network-online.target" ];
        after = [
          "network-online.target"
          "tor.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = update;
        };
      };
      systemd.timers.gpg-authorized-keys = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "1h";
          RandomizedDelaySec = "10min";
        };
      };
    })
  ];
}
