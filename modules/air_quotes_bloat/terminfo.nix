{
  pkgs,
  ...
}:

{
  environment.systemPackages = let
    mkTerminfoWrapper = package: pkgs.stdenvNoCC.mkDerivation {
      name = "${package.name}-terminfo";
      inherit (package) version;

      src = package;

      dontConfigure = true;
      dontBuild = true;

      # cp used instead of ln so that the original package can be discarded
      installPhase = ''
        runHook preInstall

        mkdir -p $out/share

        if [ -d "share/terminfo" ]; then
          cp -r "share/terminfo" $out/share/
        else
          echo "No terminfo found in share/terminfo" >&2
          exit 1
        fi

        runHook postInstall
      '';
    };
  in builtins.map mkTerminfoWrapper (with pkgs; [ kitty ]);
}
