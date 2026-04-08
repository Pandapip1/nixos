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
    systemd.tmpfiles.rules =
      let
        # Base rules for /etc/secrets itself
        baseRules = [
          "d /etc/secrets 0511 root root - -"
        ];

        # Per-path rules for each configured secret
        pathRules = lib.concatLists (
          lib.mapAttrsToList (path: val:
            let
              user = val.ownership.user;
              group = if val.ownership.group == null then "root" else val.ownership.group;
              fileMode = if val.ownership.group == null then "0400" else "0440";
              dirMode = if val.ownership.group == null then "0511" else "0551";
            in
            [
              # Create the directory with correct ownership/permissions
              "d /etc/secrets/${path} ${dirMode} ${user} ${group} - -"
              # Set permissions on existing files (z = relabel without create)
              "z /etc/secrets/${path} ${dirMode} ${user} ${group} - -"
              # Recursively relabel contents
              "Z /etc/secrets/${path} ${fileMode} ${user} ${group} - -"
            ]
          ) cfg
        );
      in
      baseRules ++ pathRules;
  };
}
