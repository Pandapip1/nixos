# The native macOS app: Hummingbird's SwiftUI app, built and packed by xtool
# (packages/xtool) with nixpkgs' open-source Swift and the macOS SDK, without
# Xcode. Hummingbird's xtool.yml describes the app: the same Info.plist, Icon
# Composer icon (compiled with its Liquid Glass settings by xtool's CarKit)
# and asset catalog the Xcode project uses.
#
# The app is ad-hoc signed without the team's entitlements, so shared-keychain
# access (ATProtoKeychainAccessGroup) won't work.
{
  lib,
  stdenv,
  callPackage,
  swift,
  swiftpm,
  apple-sdk_26,
  sqlite,
  writableTmpDirAsHomeHook,
  darwin,
  src,
  version,
  xtool ? callPackage ../../../../packages/xtool/package.nix { },
}:

let
  deps = callPackage ../../../../packages/swiftpm-deps.nix { } {
    pinData = import ./swiftpm-pins.nix;
  };
in
stdenv.mkDerivation {
  pname = "hummingbird-macos";
  inherit version src;

  nativeBuildInputs = [
    xtool
    swift
    swiftpm
    writableTmpDirAsHomeHook
    darwin.sigtool
  ];

  # The macOS 26 SDK: the newest whose SwiftUI @State is still a plain property
  # wrapper. From 27 it is a macro whose implementation (SwiftUIMacros) is a
  # closed compiler plugin that ships only with Xcode. The app also uses
  # macOS 26 APIs (glassEffect, ToolbarSpacer), so 15 is too old.
  buildInputs = [
    apple-sdk_26
    # nixpkgs' SDK leaves out headers of libraries nixpkgs provides itself
    sqlite
  ];

  configurePhase = ''
    runHook preConfigure
    ${deps.configure}
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    # The newest SDK among the inputs normally wins, and nixpkgs' Swift brings
    # the 27 SDK along; select 26 explicitly (xtool keeps SDKROOT).
    export DEVELOPER_DIR=${apple-sdk_26}
    export SDKROOT=${apple-sdk_26.sdkroot}
    # sqlite3.h and libsqlite3, for Hummingbird's CSQLite module. xtool runs
    # SwiftPM itself, so these go through clang's environment, not flags.
    export CPATH=${lib.getDev sqlite}/include''${CPATH:+:$CPATH}
    export LIBRARY_PATH=${lib.getLib sqlite}/lib''${LIBRARY_PATH:+:$LIBRARY_PATH}
    # xtool keeps its temporary files under the user's caches directory, which
    # for the build user is /var/empty; keep them in the build's instead.
    export XTL_TMPDIR="$TMPDIR"
    # The dependencies are already in .build (configurePhase); without these,
    # SwiftPM would try to clone them again, which it can't offline.
    XTOOL_BUILD_SYSTEM=native xtool dev build --triple arm64-apple-macosx \
      -Xswiftpm --disable-automatic-resolution -Xswiftpm --skip-update
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications"
    cp -R xtool/Hummingbird.app "$out/Applications/"
    runHook postInstall
  '';

  # Stripping in the fixup phase invalidates the linker's ad-hoc signature, and
  # Apple Silicon won't run an executable without a valid one. Re-sign it
  # afterwards; nixpkgs' codesign (sigtool) signs binaries, not bundles,
  # which is enough for a locally run app.
  postFixup = ''
    codesign --force --sign - "$out/Applications/Hummingbird.app/Contents/MacOS/Hummingbird"
  '';

  meta = {
    description = "Hummingbird, the native SwiftUI app for macOS";
    platforms = lib.platforms.darwin;
    mainProgram = "Hummingbird";
  };
}
