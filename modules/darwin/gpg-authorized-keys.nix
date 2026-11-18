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
  commandUser = "_gpgauthkeys";
  logFile = "/var/log/gpg-authorized-keys.log";
in
{
  config = lib.mkMerge [
    {
      gpgAuthorizedKeys.stateDir = "/var/db/gpg-authorized-keys";

      # Defined whether or not it is used: users.users decides whether it is
      # (gpgAuthorizedKeys.enable), so it can't depend on that.
      users = {
        knownUsers = [ commandUser ];
        knownGroups = [ commandUser ];
        users.${commandUser} = {
          uid = 471;
          gid = 471;
          description = "sshd AuthorizedKeysCommand (OpenPGP keys)";
          home = "/var/empty";
          shell = "/usr/bin/false";
          isHidden = true;
        };
        groups.${commandUser}.gid = 471;
      };
    }

    # Configured whether or not Remote Login is on (services.openssh.enable is
    # null, macOS's choice, by default): sshd reads it whenever it runs.
    (lib.mkIf cfg.enable {
      # sshd runs one AuthorizedKeysCommand: nix-darwin's (/bin/cat of the
      # static keys, users.users.<name>.openssh.authorizedKeys) is replaced
      # by ours, which prints those static keys first. sshd only runs a
      # command that is root-owned with no group- or world-writable directory
      # above it, and /nix/store is group-writable (nixbld), so it runs
      # /bin/sh with the script as an argument.
      environment.etc."ssh/sshd_config.d/101-authorized-keys.conf".text = lib.mkForce ''
        AuthorizedKeysCommand /bin/sh ${
          cfg.commandScript { staticKeysDir = "/etc/ssh/nix_authorized_keys.d"; }
        } %u
        AuthorizedKeysCommandUser ${commandUser}
      '';

      # Offline (seed keys and the keyring already here), so activation never
      # waits on the network; the job below fetches from the keyserver.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        echo "refreshing SSH keys from the OpenPGP web of trust (offline)..." >&2
        ${update} --offline || echo "gpg-authorized-keys: refresh failed; see above" >&2
      '';

      launchd.daemons.gpg-authorized-keys.serviceConfig = {
        # launchd can load this plist before the Nix store volume is available.
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "/bin/wait4path /nix/store && exec ${update}"
        ];
        RunAtLoad = true;
        StartInterval = 3600;
        # Reopened by launchd on every run, so newsyslog can rotate it.
        StandardOutPath = logFile;
        StandardErrorPath = logFile;
      };

      environment.etc."newsyslog.d/gpg-authorized-keys.conf".text = ''
        ${logFile}  644  3  256  *  J
      '';
    })
  ];
}
