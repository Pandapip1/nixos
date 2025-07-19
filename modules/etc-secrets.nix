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
      text = let
        ogGroup = val.ownership.group;
        group = if ogGroup == null then "root" else ogGroup;
        filePerms = if ogGroup == null then "0400" else "0440";
        dirPerms = if ogGroup == null then "0511" else "0551";
      in ''
        echo "Setting up /etc/secrets permissions..."

        mkdir -p /etc/secrets
        chown -R root:root /etc/secrets

        # Set permissions
        find /etc/secrets -type f -exec chmod ${filePerms} {} \;
        find /etc/secrets -type d -exec chmod ${dirPerms} {} \;

        # Custom ownership
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            path: val: "chown -R ${val.ownership.user}:${group} '/etc/secrets/${path}'"
          ) cfg
        )}
      '';
    };
  };
}
