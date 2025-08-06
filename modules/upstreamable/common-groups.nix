{ lib, config, ... }:

{
  /* options.users.commonGroups = {
    all = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Default secondary groups to be added to all users";
    };
    normal = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Default secondary groups to be added to all normal users (isNormalUser = true)";
    };
    system = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Default secondary groups to be added to all system users (isSystemUser = true)";
    };
  };

  config = {
    users.users = lib.mkMerge (
      lib.map (name: {
        "${name}".extraGroups = lib.mkOptionDefault (
          config.users.commonGroups.all
          ++ lib.optionals config.users.users.${name}.isNormalUser config.users.commonGroups.normal
          ++ lib.optionals config.users.users.${name}.isSystemUser config.users.commonGroups.system
        );
      }) (lib.attrNames config.users.users)
    );
  }; */
}
