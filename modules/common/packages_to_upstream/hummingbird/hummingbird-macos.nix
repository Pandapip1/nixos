# The native macOS app: Hummingbird's SwiftUI app, built and packed by xtool
# (packages/xtool) with nixpkgs' open-source Swift and the macOS SDK, without
# Xcode. Hummingbird's xtool.yml describes the app: the same Info.plist, Icon
# Composer icon (compiled with its Liquid Glass settings by xtool's CarKit)
# and asset catalog the Xcode project uses. xtool's setup hook builds,
# installs and signs it (ad hoc).
#
# Without a team signature the app has no keychain entitlements, so it can't
# use the data-protection keychain or the shared access group
# (ATProtoKeychainAccessGroup); it asks before falling back to the login
# keychain.
{
  lib,
  stdenv,
  callPackage,
  swift,
  swiftpm,
  apple-sdk_26,
  darwinMinVersionHook,
  sqlite,
  writableTmpDirAsHomeHook,
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
  ];

  # The macOS 26 SDK: the newest whose SwiftUI @State is still a plain property
  # wrapper. From 27 it is a macro whose implementation (SwiftUIMacros) is a
  # closed compiler plugin that ships only with Xcode. The app also uses
  # macOS 26 APIs (glassEffect, ToolbarSpacer), so 15 is too old.
  buildInputs = [
    apple-sdk_26
    # Hummingbird's minimum (Package.swift platforms: macOS 15). Without it
    # nixpkgs' compiler wrapper builds for its own default, 14.0.
    (darwinMinVersionHook "15.0")
    # nixpkgs' SDK leaves out headers of libraries nixpkgs provides itself
    sqlite
  ];

  postConfigure = ''
    ${deps.configure}
    # The newest SDK among the inputs normally wins, and nixpkgs' Swift brings
    # the 27 SDK along; select 26 explicitly (xtool keeps SDKROOT).
    export DEVELOPER_DIR=${apple-sdk_26}
    export SDKROOT=${apple-sdk_26.sdkroot}
    # sqlite3.h and libsqlite3, for Hummingbird's CSQLite module. xtool runs
    # SwiftPM itself, so these go through clang's environment, not flags.
    export CPATH=${lib.getDev sqlite}/include''${CPATH:+:$CPATH}
    export LIBRARY_PATH=${lib.getLib sqlite}/lib''${LIBRARY_PATH:+:$LIBRARY_PATH}
    # xtool's default is Swift Build; the native build system is used here.
    export XTOOL_BUILD_SYSTEM=native
  '';

  meta = {
    description = "Hummingbird, the native SwiftUI app for macOS";
    platforms = lib.platforms.darwin;
    mainProgram = "Hummingbird";
  };
}
