# nixpkgs' grayjay package hardcodes a `fetchurl` of
# JustCefNative-linux-x64.zip and copies it into JustCef's cache under a
# `linux-x64` path, regardless of host platform. On aarch64-linux the build
# looks for the `linux-arm64` zip instead, finds nothing cached, and falls
# back to downloading it at build time via `ensure-justcef-linux.sh` -- which
# fails in the sandbox (no network, no `curl` on PATH):
#   /build/source/JustCef/ensure-justcef-linux.sh: line 40: curl: command not found
#
# Prefetch the arm64 zip instead and point JustCef's cache dir at it,
# mirroring what the upstream package.nix does for x64.
{
  lib,
  ...
}:

{
  nixpkgs.overlays = [
    (final: prev:
      lib.optionalAttrs prev.stdenv.hostPlatform.isAarch64 {
        grayjay = prev.grayjay.overrideAttrs (
          old:
          let
            justcefNativeAarch64 = final.fetchurl {
              url = "https://static.grayjay.app/justcef/1/JustCefNative-linux-arm64.zip";
              hash = "sha256-YmAvNmBLF2HaILdQeFC6PXei45rQscNjvmJa6R2Jlus=";
            };
          in
          {
            preBuild = ''
              rm -r Grayjay.ClientServer/wwwroot/web
              cp -r ${old.frontend} Grayjay.ClientServer/wwwroot/web

              mkdir -p JustCef/obj/justcef/net8.0/1/linux-arm64
              cp ${justcefNativeAarch64} \
                JustCef/obj/justcef/net8.0/1/linux-arm64/JustCefNative-linux-arm64.zip
            '';
          }
        );
      }
    )
  ];
}
