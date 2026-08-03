{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.extraProfiles;

  profileOpts = { name, ... }: {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      path = lib.mkOption {
        type = lib.types.path;
        default = "/nix/var/nix/profiles/${name}";
        defaultText = lib.literalExpression ''"/nix/var/nix/profiles/''${name}"'';
      };
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };
      addToSessionPath = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      pathsToLink = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "/" ];
      };
      extraOutputsToInstall = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      ignoreCollisions = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  enabledProfiles = lib.filterAttrs (_: p: p.enable) cfg;

  closures = lib.mapAttrs (
    name: p:
    pkgs.buildEnv {
      name = "extra-profile-${name}";
      paths = p.packages;
      inherit (p) pathsToLink extraOutputsToInstall ignoreCollisions;
    }
  ) enabledProfiles;

  mkSetter =
    name: p: closure:
    pkgs.runCommand "set-extra-profile-${name}"
      {
        __structuredAttrs = true;
        unsafeDiscardReferences.out = true;
        meta.mainProgram = "set-extra-profile";
      }
      ''
        mkdir -p "$out/bin"
        cat > "$out/bin/set-extra-profile" <<SCRIPT
        #!${pkgs.runtimeShell}
        set -euo pipefail

        closure=${closure}
        drv=${builtins.unsafeDiscardStringContext closure.drvPath}

        if [ ! -e "\$closure" ]; then
          echo "extra-profile-${name}: \$closure is missing (garbage-collected before this unit ran)." >&2
          echo "extra-profile-${name}: attempting to rebuild/substitute from \$drv..." >&2
          if ! ${lib.getExe' config.nix.package "nix-store"} --realise "\$drv" >/dev/null; then
            echo "extra-profile-${name}: could not rebuild \$closure; run nixos-rebuild switch again." >&2
            exit 1
          fi
        fi

        exec ${lib.getExe' config.nix.package "nix-env"} -p ${p.path} --set "\$closure"
        SCRIPT
        chmod +x "$out/bin/set-extra-profile"
      '';
in
{
  options.extraProfiles = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule profileOpts);
    default = { };
  };

  config = {
    environment.profiles = lib.mkAfter (
      lib.flatten (lib.mapAttrsToList (_: p: lib.optional (p.enable && p.addToSessionPath) p.path) cfg)
    );

    systemd.services = lib.mapAttrs' (
      name: p:
      lib.nameValuePair "extra-profile-${name}" {
        description = "Point the ${name} profile at its current declared contents";
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
        serviceConfig.ExecStart = lib.getExe (mkSetter name p closures.${name});
      }
    ) enabledProfiles;
  };
}
