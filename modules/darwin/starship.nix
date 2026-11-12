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
  # The nerd-font-symbols preset draws Nerd Font icons (private-use code
  # points). Install the icon-only font; macOS falls back to it for those
  # glyphs, so the terminal keeps its own font.
  fonts.packages = [ pkgs.nerd-fonts.symbols-only ];
  environment.variables.STARSHIP_CONFIG = toString starshipConfig;
  programs.bash.interactiveShellInit = ''
    eval "$(${pkgs.starship}/bin/starship init bash)"
  '';
}
