{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.extraProfiles;
in
{
  options.extraProfiles = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }: {
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
        }
      )
    );
    default = { };
  };

  config =
    let
      enabled = lib.filterAttrs (_: p: p.enable) cfg;

      profileEnv =
        name: p:
        pkgs.buildEnv {
          name = "extra-profile-${name}";
          paths = p.packages;
          inherit (p) pathsToLink extraOutputsToInstall ignoreCollisions;
        };
    in
    {
      environment.profiles = lib.mkAfter (
        lib.flatten (lib.mapAttrsToList (_: p: lib.optional (p.enable && p.addToSessionPath) p.path) cfg)
      );

      # Build each profile's contents as part of the system build, so activation
      # only has to flip the profile symlink instead of compiling. system.checks
      # creates the build dependency without writing these paths into the built
      # system, so a generation does not pin the package set it was built with
      # (system.extraDependencies would, since it lands in the system closure).
      system.checks = lib.mapAttrsToList profileEnv enabled;

      systemd.services = lib.mapAttrs' (
        name: p:
        lib.nameValuePair "extra-profile-${name}" {
          description = "Point the ${name} profile at its current declared contents";
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "oneshot";
          serviceConfig.ExecStart = lib.getExe (
            let
              closure = profileEnv name p;
              drv = builtins.unsafeDiscardStringContext closure.drvPath;
            in
            pkgs.runCommand "set-extra-profile-${name}"
              {
                __structuredAttrs = true;
                unsafeDiscardReferences.out = true;
                meta.mainProgram = "set-extra-profile";
              }
              ''
                mkdir -p "$out/bin"
                cat > "$out/bin/set-extra-profile" <<EOF
                #!${pkgs.runtimeShell}
                set -euox pipefail

                if [ ! -e "${closure}" ]; then
                  if ! ${lib.getExe' config.nix.package "nix-store"} --realise "${drv}"; then
                    exit 1
                  fi
                fi

                exec ${lib.getExe' config.nix.package "nix-env"} -p ${p.path} --set "${closure}"
                EOF
                chmod +x "$out/bin/set-extra-profile"
              ''
          );
        }
      ) enabled;
    };
}
