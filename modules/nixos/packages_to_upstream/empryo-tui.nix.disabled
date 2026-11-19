# Empryo (github.com/proxysoul/Empryo) ships no source for either its
# terminal or desktop apps — only "SoulForge v2", its engine/core, is public;
# the apps themselves are prebuilt binaries distributed from dl.empryo.com.
# This wraps that binary directly (hash-pinned against the vendor's own
# published SHA256SUMS.txt, matched after download) rather than running its
# install.sh, which fetches and executes unpinned code from the network.
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
            url = "https://dl.empryo.com/v${version}/empryo-${version}-linux-x64.tar.gz";
            hash = "sha256-uceYlQ+Pj14VF/8eDeT2TVoU58Cq4qxnjN03fkdX1N4=";
          };
          aarch64-linux = {
            url = "https://dl.empryo.com/v${version}/empryo-${version}-linux-arm64.tar.gz";
            hash = "sha256-P4bEDNEsh2ZeIzeZhaBBVamu7GbuG3GSzroC0ebaiKw=";
          };
        };
        source =
          sources.${prev.stdenv.hostPlatform.system}
            or (throw "empryo-tui: no prebuilt binary for ${prev.stdenv.hostPlatform.system}");
      in
      {
        empryo-tui = prev.stdenv.mkDerivation {
          pname = "empryo-tui";
          inherit version;

          src = prev.fetchurl { inherit (source) url hash; };

          # `deps/lazygit` is a static Go binary, and `deps/fd`/`deps/rg` are
          # static-pie on x86_64 but dynamically linked (incl. libgcc_s) on
          # aarch64, so pull in stdenv's libgcc/libstdc++ for autoPatchelfHook.
          nativeBuildInputs = [ prev.autoPatchelfHook ];
          buildInputs = [ prev.stdenv.cc.cc.lib ];

          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/share/empryo $out/bin
            cp -r . $out/share/empryo/
            rm -f $out/share/empryo/install.sh $out/share/empryo/uninstall.sh
            ln -s $out/share/empryo/empryo $out/bin/empryo

            runHook postInstall
          '';

          meta = {
            description = "Empryo terminal UI (prebuilt binary; upstream ships no buildable source)";
            homepage = "https://empryo.com";
            license = lib.licenses.unfree;
            mainProgram = "empryo";
            platforms = builtins.attrNames sources;
            sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
          };
        };
      }
    )
  ];
}
