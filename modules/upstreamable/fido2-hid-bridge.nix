{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.fido2-hid-bridge;
  desc = "PC/SC to FIDO2 over USB HID bridge";
in
{
  options.services.fido2-hid-bridge = {
    enable = lib.mkEnableOption desc;

    package = lib.mkPackageOption pkgs "fido2-hid-bridge" { };

    polkitSupport = lib.mkEnableOption desc // {
      default = config.security.polkit.enable;
      defaultText = lib.literalExpression "config.security.polkit.enable";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [ "uhid" ];

    services.pcscd.enable = lib.mkDefault true;

    systemd.services.fido2-hid-bridge = {
      enable = lib.mkDefault true;

      description = desc;

      after = [ "pcscd.socket" ];
      requires = [ "pcscd.socket" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = "5s";

        DynamicUser = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;

        DevicePolicy = "closed";
        DeviceAllow = [ "/dev/uhid rw" ];

        BindPaths = [ "/run/pcscd/pcscd.comm" ];

        SupplementaryGroups = lib.mkIf cfg.polkitSupport [ "fido2-hid-bridge" ]; # For polkit rules
      };
      unitConfig.ConditionPathExists = "/dev/uhid";
    };

    security.polkit.extraConfig = lib.mkIf cfg.polkitSupport ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.debian.pcsc-lite.access_pcsc" && subject.isInGroup("fido2-hid-bridge")) {
          return polkit.Result.YES;
        }
      });
    '';

    users.groups.fido2-hid-bridge = lib.mkIf cfg.polkitSupport { };
  };

  meta.maintainers = with lib.maintainers; [ pandapip1 ];
}
