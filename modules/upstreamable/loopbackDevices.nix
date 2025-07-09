{
  config,
  lib,
  ...
}:
{
  options.loopbackDevices = {
    enable = lib.mkEnableOption "declarative management of loop block devices";
    devices = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submoduleWith {
          modules = [
            (
              { config, name, ... }:
              {
                options = {
                  enable = lib.mkEnableOption "this particular loop device" // {
                    default = true;
                  };

                  backingPath = lib.mkOption {
                    type = lib.types.str;
                    description = "Path to the backing file for the loop device";
                  };

                  devPath = lib.mkOption {
                    type = lib.types.str;
                    default = "/dev/loop${name}";
                    description = "Path to the device symlink to be created for the loop device";
                  };
                };
              }
            )
          ];
        }
      );
      default = { };
      description = "Declarative loopback block devices";
    };
  };

  config =
    let
      cfg = config.loopbackDevices;
    in
    lib.mkIf cfg.enable {
      boot.kernelModules = [ "loop" ];

      systemd = {
        services = lib.mapAttrs' (name: dev: {
          name = "loopback-${name}";
          value = {
            inherit (dev) enable;
            description = "Loopback setup for ${name}";
            before = [ "local-fs.target" ];
            after = [ "local-fs-pre.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = ''
                mkdir -p $(dirname "${dev.devPath}") \
                ln -sf "$(losetup --find --show "${dev.backingPath}")" "${dev.devPath}"
              '';
              ExecStop = ''
                losetup -d "$(readlink -f "${dev.devPath}")" || true \
                rm -f "${dev.devPath}"
              '';
            };
          };
        }) cfg.devices;
        paths = lib.mapAttrs' (name: dev: {
          name = "loopback-${name}";
          value = {
            inherit (dev) enable;
            description = "Watch for backing file for loop device ${name}";
            wantedBy = [ "multi-user.target" ];
            pathConfig = {
              PathExists = dev.backingPath;
              Unit = "loopback-${name}.service";
            };
          };
        }) cfg.devices;
      };
    };
}
