{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.secrets;
in
{
  options.secrets = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          ownership = {
            user = lib.mkOption {
              type = lib.types.str;
              default = "root";
              description = "User owner for the path";
            };
            group = lib.mkOption {
              type = lib.types.str;
              default = "root";
              description = "Group owner for the path";
            };
          };
        };
      }
    );
    default = { };
    description = "Custom ownership (user/group) for specific paths in /etc/secrets";
  };

  config = {
    systemd.services.etc-secrets-permissions = {
      description = "Ensure permissions on /etc/secrets";
      wantedBy = [ "multi-user.target" ];
      before = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p /etc/secrets
        chown -R root:root /etc/secrets

        # Set permissions
        find /etc/secrets -type f -exec chmod 440 {} \;
        find /etc/secrets -type d -exec chmod 550 {} \;

        # Custom ownership
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (path: val: "chown -R ${val.ownership.user}:${val.ownership.group} '/etc/secrets/${path}'") cfg
        )}
      '';
    };
  };
}
