{ pkgs, ... }:

let
  starshipConfig = pkgs.runCommand "starship.toml" { nativeBuildInputs = [ pkgs.starship ]; } ''
    starship preset nerd-font-symbols -o $out
    printf '\ncommand_timeout = 2000\n' >> $out
  '';
in
{
  environment.systemPackages = [ pkgs.starship ];
  environment.variables.STARSHIP_CONFIG = toString starshipConfig;
  programs.bash.interactiveShellInit = ''
    eval "$(${pkgs.starship}/bin/starship init bash)"
  '';
}
