{
  lib,
  pkgs,
  ...
}:

let
  allNotoFonts = lib.filter (x: x != null) (
    map (
      n:
      let
        t = builtins.tryEval pkgs.${n};
      in
      if t.success && lib.attrsets.isDerivation t.value then t.value else null
    ) (lib.filter (n: lib.hasPrefix "noto-fonts" n) (builtins.attrNames pkgs))
  );
  allNerdFonts = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
in
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
    packages =
      allNerdFonts
      ++ allNotoFonts
      ++ (with pkgs; [
        orbitron
      ]);
  };
}
