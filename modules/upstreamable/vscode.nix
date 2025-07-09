{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.programs.vscode;
in
{
  options.programs.vscode = {
    enable = lib.mkEnableOption "Visual Studio Code or VSCodium with extensions";

    package = lib.mkPackageOption pkgs "vscode" { };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "List of VSCode extensions to install";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.vscode-with-extensions.override {
        vscode = cfg.package;
        vscodeExtensions = cfg.extensions;
      })
    ];
  };
}
