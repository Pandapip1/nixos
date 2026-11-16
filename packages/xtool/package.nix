# xtool (https://xtool.sh): builds and packs SwiftPM apps without Xcode. This
# is the fork in src.nix, which adds macOS apps, asset catalogs and Icon
# Composer icons (compiled by its CarKit, not Apple's actool).
#
# Built entirely from source. Two dependencies download prebuilt binaries by
# default, and both are replaced:
# - xtool-core's libimobiledevice, libplist, usbmuxd and OpenSSL frameworks:
#   XTL_SYSTEM_LIBRARIES=1 makes it use nixpkgs' libraries instead.
# - swift-rcodesign's Rust code-signing library: built by rcodesign.nix, and
#   the checkout's manifest is patched to use it.
{
  lib,
  stdenv,
  callPackage,
  replaceVars,
  runCommand,
  perl,
  swift,
  swiftpm,
  pkg-config,
  makeWrapper,
  writableTmpDirAsHomeHook,
  libimobiledevice,
  libimobiledevice-glue,
  libplist,
  libusbmuxd,
  openssl,
  zlib,
  resvg,
  rcodesign,
  darwin,
}:

let
  inherit (callPackage ./src.nix { }) version src;

  deps = callPackage ../swiftpm-deps.nix { } {
    pinData = import ./swiftpm-pins.nix;
    overrides.swift-rcodesign =
      checkout:
      let
        library = callPackage ./rcodesign.nix { src = checkout; };
      in
      runCommand "swift-rcodesign-from-source" { nativeBuildInputs = [ perl ]; } ''
        cp -r ${checkout} $out
        chmod -R u+w $out
        # The library comes from rcodesign.nix rather than a download: a
        # system library module over its header, linked from there.
        perl -0pi -e 's/\.binaryTarget\(\s*name:\s*"RCodesignBinary".*?\)/.systemLibrary(name: "RCodesignBinary", path: "include")/s' \
          $out/Package.swift
        grep -q 'systemLibrary(name: "RCodesignBinary"' $out/Package.swift
        ! grep -q binaryTarget $out/Package.swift
        cat > $out/include/module.modulemap <<'MAP'
        module RCodesignBinary [extern_c] {
            header "rcodesign.h"
            link "rcodesign_ffi"
            export *
        }
        MAP
        mkdir -p $out/lib && ln -s ${library}/lib/librcodesign_ffi.a $out/lib/
      '';
  };
in
stdenv.mkDerivation {
  pname = "xtool";
  inherit version src;

  nativeBuildInputs = [
    swift
    swiftpm
    pkg-config
    makeWrapper
    writableTmpDirAsHomeHook
  ];
  buildInputs = [
    libimobiledevice
    libimobiledevice-glue
    libplist
    libusbmuxd
    openssl
    zlib
  ];

  env.XTL_SYSTEM_LIBRARIES = "1";

  # Adding xtool to a package's nativeBuildInputs builds it as an xtool app;
  # see setup-hook.sh.
  setupHook = replaceVars ./setup-hook.sh {
    rcodesign = "${rcodesign}/bin/rcodesign";
  };

  configurePhase = ''
    runHook preConfigure
    ${deps.configure}
    # rcodesign's static library, linked by its module map's `link`.
    export LIBRARY_PATH="$PWD/.build/checkouts/swift-rcodesign/lib''${LIBRARY_PATH:+:$LIBRARY_PATH}"
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    # No prebuilt swift-syntax for macros: SwiftPM would try to download it
    # (and, failing to in the sandbox, exit with an error after building).
    swift build -c release --product xtool --build-system native \
      --disable-sandbox --disable-automatic-resolution --skip-update \
      --disable-experimental-prebuilts
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 .build/release/xtool "$out/bin/xtool"
    # xtool runs SwiftPM, which signs what it links with codesign (here
    # sigtool's), and renders SVGs (asset catalogs, icons) with resvg.
    wrapProgram "$out/bin/xtool" \
      --suffix PATH : ${lib.makeBinPath [ swift swiftpm resvg darwin.sigtool ]}
    runHook postInstall
  '';

  meta = {
    description = "Cross-platform Xcode replacement: build and pack SwiftPM apps without Xcode";
    homepage = "https://github.com/Pandapip1/xtool";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "xtool";
  };
}
