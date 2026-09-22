{ lib, ... }:

{
  # pkgs.grayjay's src (fetchFromGitLab, fetchSubmodules + fetchLFS) pulls in
  # JustCef's ENTIRE vendored CEF payload: native/third_party/cef/ has 8 full
  # per-platform CEF SDK archives (linux64, linuxarm64, macosarm64 x2,
  # macosx64 x2, windows64 x2 - each several hundred MB, ~4-5GB combined),
  # and prebuilt/ has 5 more per-platform runtime dirs. None of that is
  # platform-conditional at the fetch level - fetchLFS downloads all of it,
  # every time, regardless of which single platform is actually being built.
  #
  # None of it is needed at fetch time. JustCef/DotCef.csproj (the only
  # JustCef project this package's `projectFile` list references) is a pure
  # C# project with no native build step - it copies prebuilt/<rid>/** as
  # content files - but modules/patches/grayjay-cef-unvendor/ builds CEF from
  # JustCef's own native/CMakeLists.txt against pkgs.cef-binary instead, and
  # that native build reproduces everything prebuilt/<platform>/ supplies. So
  # this fetch skips prebuilt/ entirely too, not just native/third_party/cef/.
  #
  # This overlay replaces grayjay's src with a hand-rolled fetch that skips
  # LFS smudge entirely on checkout (GIT_LFS_SKIP_SMUDGE=1 - writes ~130-byte
  # pointer files instead of downloading) and leaves it at that - no targeted
  # pull for anything under JustCef. Verified directly (standalone
  # reproduction against the real repo, not guessed): with smudge skipped,
  # the full JustCef tree is 12MB; native/third_party/cef/*.tar.bz2 and every
  # prebuilt/<platform>/ dir stayed as confirmed ~134-byte LFS pointers (one
  # tar.bz2 pointer alone declares `size 513681969` for the linuxarm64
  # archive - so all 8 of those plus 5 prebuilt/ dirs together are several
  # GB). Net effect: JustCef's fetch drops from an estimated 4.5-5.5GB to
  # ~12MB. Nothing is lost even before grayjay-cef-unvendor lands: the
  # excluded content was never used by the stock (non-unvendored) build
  # either (confirmed by reading DotCef.csproj directly), so leaving them as
  # pointer stubs instead of real binaries only matters once something
  # actually needs prebuilt/<platform>/ again - which unvendoring avoids by
  # building the same content from source instead.
  #
  # This fetch is now platform-independent (nothing platform-specific is
  # pulled), so a single outputHash covers every system - unlike the old
  # per-platform pull, which had different content per target.
  #
  # Note: modules/patches/fetchgit-lfs/ (already in this repo) takes a
  # different, complementary approach to the same underlying slow-fetch
  # symptom - it patches nix-prefetch-git to use a parallel `git lfs pull`
  # instead of serial checkout-triggered smudge, which speeds up downloading
  # the SAME (full, all-platforms) content rather than reducing what's
  # downloaded. Both overlays reassign `grayjay`/`grayjay.src`, so only one
  # can actually be in effect at a time depending on nixpkgs.overlays list
  # order - this one replaces `src` outright rather than building on
  # `old.src`, so if it's applied after fetchgit-lfs's overlay, the parallel-
  # LFS fetcher becomes moot for grayjay specifically (still valid, generic,
  # unused code). Left for the user to reconcile which one should stay
  # active; this one's reduction in bytes fetched is the larger win of the
  # two and doesn't need the other to also be enabled.
  nixpkgs.overlays = [
    (final: prev: {
      grayjay = prev.grayjay.overrideAttrs (old: {
        src = final.stdenv.mkDerivation {
          name = "grayjay-source-cef-excluded";
          nativeBuildInputs = [
            final.git
            final.git-lfs
            final.cacert
          ];
          builder = final.writeShellScript "builder" ''
            source $stdenv/setup
            ${lib.getExe' final.bash "bash"} ${./fetch-grayjay-src.sh} "$out"
          '';
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          # TODO: placeholder - the previous real hash (for the old,
          # per-platform prebuilt/<platform>/ fetch) no longer applies now
          # that prebuilt/ is skipped entirely too. Replace with the real
          # hash from the first build attempt's mismatch error once disk
          # space and the build queue allow running it.
          outputHash = lib.fakeHash;
        };
      });
    })
  ];
}
