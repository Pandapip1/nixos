{
  lib,
  pkgs,
  config,
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

  singletonFontsDir = "${config.extraProfiles.singleton.path}/share/fonts";
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
      localConf = ''
        <?xml version='1.0'?>
        <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
        <fontconfig>
          <dir>${singletonFontsDir}</dir>
        </fontconfig>
      '';
    };
  };

  extraProfiles.singleton.packages =
    allNerdFonts
    ++ allNotoFonts
    ++ (with pkgs; [
      orbitron
    ]);

  systemd.services.warm-singleton-font-cache = {
    description = "Warm the fontconfig cache for the singleton profile's fonts";
    after = [ "extra-profile-singleton.service" ];
    requires = [ "extra-profile-singleton.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if [ -d "${singletonFontsDir}" ]; then
        ${lib.getExe' pkgs.fontconfig "fc-cache"} -f "${singletonFontsDir}"
      fi
    '';
  };
}
