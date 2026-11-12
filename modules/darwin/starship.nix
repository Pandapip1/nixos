{ pkgs, ... }:

let
  starshipConfig = pkgs.runCommand "starship.toml" { nativeBuildInputs = [ pkgs.starship ]; } ''
    # Top-level keys must come before the first [table], or TOML puts them
    # inside it (the preset ends with [zig]).
    {
      printf 'command_timeout = 2000\n\n'
      starship preset nerd-font-symbols
    } > $out
  '';
in
{
  environment.systemPackages = [ pkgs.starship ];
  environment.variables.STARSHIP_CONFIG = toString starshipConfig;
  programs.bash.interactiveShellInit = ''
    eval "$(${pkgs.starship}/bin/starship init bash)"
  '';
}
