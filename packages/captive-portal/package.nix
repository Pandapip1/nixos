{
  lib,
  stdenv,
  swift,
  swiftpm,
  writableTmpDirAsHomeHook,
  pkg-config,
  wrapGAppsHook4,
  webkitgtk_6_0,
  gtk4,
  glib,
  glib-networking,
}:

# Small WebKit window for logging in to captive portals; see Package.swift.
stdenv.mkDerivation {
  pname = "captive-portal";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Package.swift
      ./Sources
    ];
  };

  nativeBuildInputs = [
    swift
    swiftpm
    writableTmpDirAsHomeHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    webkitgtk_6_0
    gtk4
    glib
    # TLS for WebKitGTK's network process.
    glib-networking
  ];

  # Let the real pkg-config resolve WebKitGTK's flags (see Package.swift).
  preBuild = lib.optionalString stdenv.hostPlatform.isLinux ''
    for flag in $(pkg-config --cflags webkitgtk-6.0); do
      swiftpmFlagsArray+=(-Xcc "$flag")
    done
    for flag in $(pkg-config --libs webkitgtk-6.0); do
      # Only library paths and names go to the linker; driver flags such as
      # -pthread don't mean anything to ld (and Swift links pthread anyway).
      case "$flag" in
        -L* | -l*) swiftpmFlagsArray+=(-Xlinker "$flag") ;;
      esac
    done
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 "$(swiftpmBinPath)/captive-portal" "$out/bin/captive-portal"
    runHook postInstall
  '';

  meta = {
    description = "WebKit window for captive portals, resolving through the network's own DNS";
    mainProgram = "captive-portal";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}
