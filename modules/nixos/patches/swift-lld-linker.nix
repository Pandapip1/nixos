# nixpkgs marks swiftc broken on aarch64-linux: it fails to link with the
# gold linker on Hydra (nixpkgs commit 7302e41b, referencing
# https://hydra.nixos.org/build/349228350). The actual fix -- building
# swiftc itself with LLD instead -- landed in nixpkgs PR #574002 (merge
# 10b5819c), bundled into an unrelated Swift 6.3.3 -> 6.4.0 version bump on
# an otherwise unpromoted `staging` branch snapshot (2271 commits ahead,
# 1152 behind nixos-unstable at the time) that would force a near-total
# rebuild if pinned directly.
#
# This backports just the packaging-level mechanism from that PR -- an
# `lld` wrapper (llvmPackages.lld itself isn't wrapped, which breaks
# rpaths) plus the `CMAKE_LINKER_TYPE=LLD` cmake flag -- onto the swiftc
# used at every bootstrap stage, via `swiftPackages.overrideScope`, rather
# than switching the whole Swift toolchain to a different nixpkgs commit.
{
  lib,
  ...
}:

{
  nixpkgs.overlays = [
    (final: prev:
      lib.optionalAttrs (prev.stdenv.hostPlatform.isLinux && prev.stdenv.hostPlatform.isAarch64) (
        let
          swiftPackages = prev.swiftPackages.overrideScope (
            sfinal: sprev:
            let
              lldWrapper = prev.stdenvNoCC.mkDerivation {
                pname = "lld-wrapper";
                version = lib.getVersion prev.llvmPackages.lld;
                dontUnpack = true;
                buildCommand = ''
                  mkdir -p "$out/bin"
                  ln -s ${lib.getExe' prev.llvmPackages.bintools "ld"} "$out/bin/ld"
                  ln -s ${lib.getExe' prev.llvmPackages.bintools "ld.lld"} "$out/bin/ld.lld"
                '';
              };
            in
            {
              swiftc = sprev.swiftc.overrideAttrs (old: {
                nativeBuildInputs = old.nativeBuildInputs ++ [ lldWrapper ];
                cmakeFlags = old.cmakeFlags ++ [ (lib.cmakeFeature "CMAKE_LINKER_TYPE" "LLD") ];
                # `strip` on swift-frontend (a very large binary) is the repeated
                # OOM point building this natively on memory-constrained aarch64
                # hardware; skip it rather than keep retrying for a lucky window.
                dontStrip = true;
                meta = old.meta // {
                  broken = false;
                };
              });
            }
          );
        in
        {
          inherit swiftPackages;
          inherit (swiftPackages) swift swiftc swiftpm;
        }
      )
    )
  ];
}
