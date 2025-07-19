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
              type = lib.types.nullOr lib.types.str;
              default = null;
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
    system.activationScripts.etcSecretsPermissions = {
      text = ''
        echo "Setting up /etc/secrets permissions..."

        mkdir -p /etc/secrets
        chown -R root:root /etc/secrets

        # Set permissions
        find /etc/secrets -type f -exec chmod 0400 {} \;
        find /etc/secrets -type d -exec chmod 0511 {} \;

        # Custom ownership
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (path: val: ''
            find '/etc/secrets/${path}' -type f -exec chmod ${
              if val.ownership.group == null then "0400" else "0440"
            } {} \;
            find '/etc/secrets/${path}' -type d -exec chmod ${
              if val.ownership.group == null then "0511" else "0551"
            } {} \;
            chown -R ${val.ownership.user}:${
              if val.ownership.group == null then "root" else val.ownership.group
            } '/etc/secrets/${path}'
          '') cfg
        )}
      '';
    };
  };
}
