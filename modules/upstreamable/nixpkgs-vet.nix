{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.programs.nixpkgs-vet;
in
{
  options.programs.nixpkgs-vet = {
    enable = lib.mkEnableOption "nixpkgs-vet";
    package = lib.mkPackageOption pkgs "nixpkgs-vet" { };
    nixPackage = lib.mkPackageOption pkgs "nix" {
      default = config.nix.package;
      defaultText = literalExpression "config.nix.package";
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ cfg.package ];
      variables.NIXPKGS_VET_NIX_PACKAGE = lib.getBin cfg.nixPackage;
    };
  };

  meta.maintainers = with lib.maintainers; [ pandapip1 ];
}
