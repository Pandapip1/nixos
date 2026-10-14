{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.programs.fastfetch;
in
{
  options.programs.fastfetch = {
    enable = lib.mkEnableOption "fastfetch";
    package = lib.mkPackageOption pkgs "fastfetch" { };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ cfg.package ];
    };
  };

  meta.maintainers = with lib.maintainers; [ pandapip1 ];
}
