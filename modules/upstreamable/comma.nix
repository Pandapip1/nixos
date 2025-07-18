{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.programs.comma;
in
{
  options.programs.comma = {
    enable = lib.mkEnableOption "comma";
    package = lib.mkPackageOption pkgs "comma";
    enableBashIntegration = lib.mkEnableOption "comma command-not-found handler for bash" // {
      default = true;
    };
    enableZshIntegration = lib.mkEnableOption "comma command-not-found handler for zsh" // {
      default = true;
    };
    enableFishIntegration = lib.mkEnableOption "comma command-not-found handler for fish" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      environment.systemPackages = [ cfg.package ];
      bash.interactiveShellInit = lib.mkIf cfg.enableBashIntegration ''
        source ${cfg.package}/etc/profile.d/comma-command-not-found.sh
      '';
      zsh.interactiveShellInit = lib.mkIf cfg.enableZshIntegration ''
        source ${cfg.package}/etc/profile.d/comma-command-not-found.sh
      '';
      # See https://github.com/bennofs/nix-index/issues/126
      fish.interactiveShellInit =
        let
          wrapper = pkgs.writeScript "command-not-found" ''
            #!${lib.getExe pkgs.bash}
            source ${pkgs.comma-with-db}/etc/profile.d/command-not-found.sh
            command_not_found_handle "$@"
          '';
        in
        ''
          function __fish_command_not_found_handler --on-event fish_command_not_found
              ${wrapper} $argv
          end
        '';

      # Disable *other* command-not-found handlers
      command-not-found.enable = lib.mkIf (
        cfg.enableBashIntegration || cfg.enableZshIntegration || cfg.enableFishIntegration
      ) (lib.mkDefault false);
      programs.nix-index = {
        enableBashIntegration = lib.mkIf (cfg.enableBashIntegration) (lib.mkDefault false);
        enableZshIntegration = lib.mkIf (cfg.enableZshIntegration) (lib.mkDefault false);
        enableFishIntegration = lib.mkIf (cfg.enableFishIntegration) (lib.mkDefault false);
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ pandapip1 ];
}
