# See empryo-tui.nix: same vendor, same binary-only distribution. This is the
# Linux desktop (Electron) build, shipped as an AppImage.
{
  lib,
  ...
}:

{
  nixpkgs.overlays = [
    (_: prev:
      let
        version = "3.11.0-beta";
        sources = {
          x86_64-linux = {
            url = "https://dl.empryo.com/v${version}/Empryo-${version}-linux-x86_64.AppImage";
            hash = "sha256-KHA5PzNM7LRLcX5LO1hJYfr3XziWahnFAMV/QC4EWes=";
          };
          aarch64-linux = {
            url = "https://dl.empryo.com/v${version}/Empryo-${version}-linux-arm64.AppImage";
            hash = "sha256-/3zEyALdQoJpPcI1VHpe8E/bLgnEBEbWfV5MbrvFCck=";
          };
        };
        source =
          sources.${prev.stdenv.hostPlatform.system}
            or (throw "empryo-gui: no prebuilt binary for ${prev.stdenv.hostPlatform.system}");

        pname = "empryo-gui";
        src = prev.fetchurl { inherit (source) url hash; };
        appimageContents = prev.appimageTools.extract { inherit pname version src; };

        # The bundled empryo-desktop.desktop's Exec= line points at the
        # AppImage's own AppRun, which doesn't exist once unpacked, so this
        # writes a fresh desktop entry instead of patching that one.
        desktopItem = prev.makeDesktopItem {
          name = pname;
          desktopName = "Empryo";
          comment = "Empryo desktop GUI";
          exec = pname;
          icon = pname;
          categories = [ "Development" ];
        };
      in
      {
        empryo-gui = prev.appimageTools.wrapType2 {
          inherit pname version src;

          extraInstallCommands = ''
            install -m 444 -D ${appimageContents}/empryo-desktop.png \
              $out/share/icons/hicolor/512x512/apps/${pname}.png
            mkdir -p $out/share/applications
            cp ${desktopItem}/share/applications/*.desktop $out/share/applications/
          '';

          meta = {
            description = "Empryo desktop GUI (prebuilt AppImage; upstream ships no buildable source)";
            homepage = "https://empryo.com";
            license = lib.licenses.unfree;
            mainProgram = pname;
            platforms = builtins.attrNames sources;
            sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
          };
        };
      }
    )
  ];
}
