{
  lib,
  pkgs,
  ...
}:

{
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        # Use Noto for everything
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "Noto Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
      useEmbeddedBitmaps = true;
    };
    packages = (builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts)) ++ (lib.attrValues (
      lib.filterAttrs
        (name: value:
          lib.hasPrefix "noto-fonts" name &&
          lib.isDerivation value
        )
        pkgs
    )) ++ (with pkgs; [
      orbitron
    ]);
  };
}
