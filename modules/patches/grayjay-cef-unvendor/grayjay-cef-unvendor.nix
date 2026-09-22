{ lib, ... }:

{
  # Real CEF unvendoring: build JustCef/native/'s own C++ glue code
  # (native/src/, essentially CEF's stock cefsimple sample app renamed to
  # dotcefnative) from source against pkgs.cef-binary, instead of using the
  # prebuilt dotcefnative binary that ships in prebuilt/<platform>/ (still
  # fetched by ../grayjay-cef-exclude/ as a safety net - see below).
  #
  # Why this works: native/CMakeLists.txt's UnpackCEF() (native/cmake/
  # UnpackCEF.cmake) does NOT itself download anything - it only extracts an
  # already-present third_party/cef/cef_binary_<version>_<platform>_minimal
  # .tar.bz2 archive, or skips entirely (no extraction, no existence check on
  # the archive) if third_party/cef/cef_binary_<version>_<platform>_minimal/
  # already exists as a directory. pkgs.cef-binary's own installPhase is
  # `cp --recursive . $out` of the official CEF minimal-distribution tarball
  # plus a few patchelf calls for NixOS's non-FHS runtime paths - i.e. its
  # output tree IS structurally the same thing UnpackCEF would have
  # extracted. So: pre-populate that exact directory from cef-binary's
  # output before configuring, and UnpackCEF's own directory-exists check
  # short-circuits straight past both the download and the extraction.
  #
  # native/src/CMakeLists.txt (confirmed by reading it directly) is CEF's
  # own stock cefsimple sample, barely modified - it uses CEF's own
  # COPY_FILES/CEF_BINARY_FILES/CEF_RESOURCE_FILES cmake macros (shipped
  # inside the CEF distribution itself) to copy libcef.so, chrome-sandbox,
  # locales, .pak files, icudtl.dat etc. alongside dotcefnative into the
  # build output directory automatically - i.e. a successful native build
  # reproduces everything prebuilt/<platform>/ currently supplies, not just
  # the binary. We copy the whole build output directory over
  # prebuilt/<platform>/ for exactly this reason - DotCef.csproj's existing
  # RuntimeIdentifier-gated Content items (which copy prebuilt/<rid>/** as
  # part of the dotnet build) need no changes to pick up the natively-built
  # files instead of the vendored ones.
  #
  # 0001-skip-clang-format-download.patch removes a live network fetch
  # (tools/buildtools/download_from_google_storage.py, for clang-format dev
  # tooling, unrelated to the compiled output) that native/CMakeLists.txt
  # otherwise runs unconditionally at configure time - this would fail
  # outright with no network access in a Nix build sandbox.
  #
  # ../grayjay-cef-exclude/ no longer fetches prebuilt/<platform>/ at all
  # (skips LFS smudge entirely, everything under JustCef stays as pointer
  # stubs) - this overlay's preBuild unconditionally rm -rf's and replaces
  # that directory regardless of what's in it beforehand, so that's fine
  # either way. But this DOES mean grayjay now has no working fallback CEF
  # if this native build turns out not to work: this overlay has been
  # written and eval-checked but NOT build-verified (no `nix build` was run
  # to confirm the native build actually compiles, links, and produces a
  # working dotcefnative - see the known-unverified points below). If this
  # doesn't pan out, re-adding a targeted `git lfs pull
  # --include="prebuilt/<platform>/**"` back into
  # ../grayjay-cef-exclude/fetch-grayjay-src.sh (removed once this module
  # was written, under the assumption this build would replace the need for
  # it) restores a working fallback.
  #
  # Known-unverified points (real risks a `nix build` still needs to settle,
  # not just "should be fine"):
  # - Whether cef-binary's installPhase patchelf calls (written for its
  #   default 151.x version) still apply cleanly to the older 141.x archive
  #   layout this override targets - unverified, the archives may differ.
  # - Whether clang_18's default C++ stdlib choice on this system is ABI-
  #   compatible with the prebuilt libcef.so cef-binary ships (CEF is a
  #   released Chromium build with a fixed ABI expectation).
  # - CEF's own SET_LINUX_SUID_PERMISSIONS cmake macro (invoked on
  #   chrome-sandbox in native/src/CMakeLists.txt) - its actual
  #   implementation lives inside CEF_ROOT/cmake (i.e. inside cef-binary's
  #   output, not JustCef's repo), wasn't read, and may or may not matter
  #   for a Nix store binary that was never going to run setuid anyway.
  # - CMAKE_SYSTEM_PROCESSOR-based platform auto-detection (linuxarm64 vs
  #   linux64) is trusted rather than forced via -D, since the top-level
  #   CMakeLists.txt's unconditional set() calls would just clobber a
  #   command-line override anyway - should auto-detect correctly for a
  #   native (non-cross) build, but unverified.
  nixpkgs.overlays = [
    (final: prev: {
      grayjay = prev.grayjay.overrideAttrs (
        old:
        let
          system = final.stdenv.hostPlatform.system;
          # dotnet RID naming (matches ../grayjay-cef-exclude/'s `platform`)
          # vs. CEF's own platform naming (CEF_PLATFORM in
          # native/CMakeLists.txt) - these are two different strings for the
          # same architecture and both are needed below.
          ridPlatform =
            {
              aarch64-linux = "linux-arm64";
              x86_64-linux = "linux-x64";
            }
            .${system} or (throw "grayjay-cef-unvendor: unsupported system ${system}");
          cefPlatform =
            {
              aarch64-linux = "linuxarm64";
              x86_64-linux = "linux64";
            }
            .${system} or (throw "grayjay-cef-unvendor: unsupported system ${system}");
          # The exact version JustCef's native/CMakeLists.txt pins
          # (CEF_VERSION), confirmed live at Spotify's CDN.
          cefVersion = "141.0.10";
          cefGitRevision = "1d65b0d";
          cefChromiumVersion = "141.0.7390.123";
          cefFullVersion = "${cefVersion}+g${cefGitRevision}+chromium-${cefChromiumVersion}";
          # Matches UnpackCEF.cmake's `set(CEF_DISTRIBUTION
          # "cef_binary_${version}_${platform}_minimal")` exactly - this is
          # the directory name it checks IS_DIRECTORY on before deciding
          # whether to extract anything.
          cefDistName = "cef_binary_${cefFullVersion}_${cefPlatform}_minimal";
          cefBinary = final.cef-binary.override {
            version = cefVersion;
            gitRevision = cefGitRevision;
            chromiumVersion = cefChromiumVersion;
            # Real, verified hash for aarch64-linux (downloaded the actual
            # archive and hashed it directly, not guessed). x86_64-linux
            # hasn't been fetched/hashed yet - placeholder until this is
            # built on an x86_64-linux host that uses grayjay.
            srcHashes = {
              aarch64-linux = "sha256-CJGCJRIMV8UBummf6uHe8NV0Y+HWRZTKZuNB08xD30Y=";
              x86_64-linux = lib.fakeHash;
            };
          };
        in
        {
          patches = (old.patches or [ ]) ++ [
            ./0001-skip-clang-format-download.patch
          ];

          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
            final.cmake
            final.llvmPackages_18.clang
          ];

          preBuild = (old.preBuild or "") + ''
            (
              set -euo pipefail
              justcef_native="JustCef/native"
              cef_root_dir="$justcef_native/third_party/cef/${cefDistName}"

              echo "=== pre-populating CEF_ROOT from pkgs.cef-binary (skips JustCef's own UnpackCEF fetch/extract) ===" >&2
              mkdir -p "$(dirname "$cef_root_dir")"
              rm -rf "$cef_root_dir"
              cp -r --no-preserve=mode,ownership ${cefBinary} "$cef_root_dir"
              chmod -R u+w "$cef_root_dir"

              echo "=== building JustCef/native (dotcefnative) from source ===" >&2
              build_dir=$(mktemp -d)
              cmake -S "$justcef_native" -B "$build_dir" \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_C_COMPILER=${lib.getExe' final.llvmPackages_18.clang "clang"} \
                -DCMAKE_CXX_COMPILER=${lib.getExe' final.llvmPackages_18.clang "clang++"}
              cmake --build "$build_dir" --config Release -j"''${NIX_BUILD_CORES:-1}"

              echo "=== substituting the natively-built dotcefnative + runtime files for the vendored prebuilt/${ridPlatform}/ ===" >&2
              rm -rf "JustCef/prebuilt/${ridPlatform}"
              mkdir -p "JustCef/prebuilt/${ridPlatform}"
              cp -r "$build_dir/Release/." "JustCef/prebuilt/${ridPlatform}/"
              chmod +x "JustCef/prebuilt/${ridPlatform}/dotcefnative"
              rm -rf "$build_dir"
            )
          '';
        }
      );
    })
  ];
}
