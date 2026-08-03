{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.nix-gc;

  profileOpts = { name, ... }: {
    options = {
      path = lib.mkOption {
        type = lib.types.path;
        default = "/nix/var/nix/profiles/${name}";
        defaultText = lib.literalExpression ''"/nix/var/nix/profiles/''${name}"'';
        description = "Profile to garbage-collect.";
      };

      configurationLimit = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = 16;
        description = "Number of generations to keep. null disables pruning for this profile.";
      };
    };
  };

  deleteGenerationsLines = lib.concatStringsSep "\n" (
    lib.filter (s: s != "") (
      lib.mapAttrsToList (
        _: p:
        lib.optionalString (p.configurationLimit != null)
          "${lib.getExe' config.nix.package "nix-env"} --delete-generations +${toString p.configurationLimit} --profile ${p.path}"
      ) cfg.profiles
    )
  );
in
{
  imports = [
    (lib.mkAliasOptionModule
      [ "nix-gc" "configurationLimit" ]
      [ "nix-gc" "profiles" "system" "configurationLimit" ]
    )
  ];

  options.nix-gc = {
    profiles = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule profileOpts);
      default.system = { };
      description = ''
        Named profiles to prune generations for, each with its own path
        and generation limit. All are pruned by the single nix-gc run,
        followed by one nix-collect-garbage sweep.
      '';
    };

    startAt = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "systemd calendar expression for the nix-gc run.";
    };
  };

  config = {
    systemd.services.nix-gc = lib.mkForce {
      description = "Nix garbage collector";
      script = ''
        ${deleteGenerationsLines}
        exec ${lib.getExe' config.nix.package "nix-collect-garbage"}
      '';
      serviceConfig.Type = "oneshot";
      startAt = cfg.startAt;
    };

    systemd.timers.nix-gc.timerConfig.Persistent = lib.mkForce true;
  };
}
