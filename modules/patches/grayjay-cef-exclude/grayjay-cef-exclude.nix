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
  # It's all unnecessary except one directory: JustCef/DotCef.csproj (the
  # only JustCef project this package's `projectFile` list references) is a
  # pure C# project with no native build step - its RuntimeIdentifier-gated
  # <ItemGroup>s just copy prebuilt/<rid>/** as content files. It never
  # touches native/third_party/cef/ at all (that's only used by JustCef's
  # own native/CMakeLists.txt build, which this package never invokes), and
  # dotnet only selects ONE prebuilt/<rid>/ for a given build.
  #
  # This overlay replaces grayjay's src with a hand-rolled fetch that skips
  # LFS smudge entirely on first checkout (git lfs install --skip-smudge
  # equivalent via GIT_LFS_SKIP_SMUDGE=1 - writes ~130-byte pointer files
  # instead of downloading), then does one targeted `git lfs pull
  # --include="prebuilt/<platform>/**"` inside just the JustCef submodule.
  # Verified directly (standalone reproduction against the real repo, not
  # guessed): with smudge skipped, the full JustCef tree is 12MB; after the
  # targeted pull it's 641MB (316MB of that genuinely is prebuilt/linux-arm64,
  # the rest base source); native/third_party/cef/*.tar.bz2 stayed as
  # confirmed ~134-byte LFS pointers (one declares `size 513681969` for the
  # linuxarm64 archive alone - so all 8 of those alone would be several GB),
  # and the other 4 prebuilt/<platform>/ dirs stayed in the low-hundreds-of-KB
  # range (pointer stubs only). Net effect: JustCef's fetch drops from an
  # estimated 4.5-5.5GB to ~330MB, roughly a 93-95% reduction - and nothing
  # is lost, since the excluded content was never used by this build to
  # begin with (confirmed by reading DotCef.csproj directly, not assumed).
  #
  # Leaving the excluded paths as tiny LFS pointer text files (rather than
  # fully absent) is deliberate and safe: dotnet's RuntimeIdentifier-gated
  # <ItemGroup>s in DotCef.csproj simply never select them for a linux-arm64
  # (or linux-x64) build, so their content - real binary or pointer stub -
  # is irrelevant to what actually gets built.
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
      grayjay = prev.grayjay.overrideAttrs (
        old:
        let
          system = final.stdenv.hostPlatform.system;
          platform =
            {
              aarch64-linux = "linux-arm64";
              x86_64-linux = "linux-x64";
            }
            .${system} or (throw "grayjay-cef-exclude: unsupported system ${system}");
          # Per-platform, since each fetches different prebuilt/<platform>/**
          # content. Only aarch64-linux (ilama, the host this was built for)
          # has a real hash so far; x86_64-linux is a placeholder until this
          # is actually built on an x86_64-linux host that uses grayjay -
          # `nix build` there once and swap in the real hash from the
          # mismatch error, same as this one was obtained.
          outputHash =
            {
              aarch64-linux = "sha256-2hQIvimycaGgqdG0BqJYlFy/aOwV3CnIVFaR50uanJU=";
            }
            .${system} or lib.fakeHash;
        in
        {
          src = final.stdenv.mkDerivation {
            name = "grayjay-source-cef-excluded";
            nativeBuildInputs = [
              final.git
              final.git-lfs
              final.cacert
            ];
            builder = final.writeShellScript "builder" ''
              source $stdenv/setup
              ${lib.getExe' final.bash "bash"} ${./fetch-grayjay-src.sh} "$out" "${platform}"
            '';
            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            inherit outputHash;
          };
        }
      );
    })
  ];
}
