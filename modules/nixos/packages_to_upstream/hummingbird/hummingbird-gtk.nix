# The Linux GTK4 app, built offline from pinned SwiftPM dependencies.
{
  lib,
  stdenv,
  fetchgit,
  swift,
  swiftpm,
  pkg-config,
  makeBinaryWrapper,
  makeDesktopItem,
  writableTmpDirAsHomeHook,
  wrapGAppsHook4,
  gst_all_1,
  librsvg,
  glib-networking,
  adwaita-icon-theme,
  src,
  version ? "0.1.0",
  pinData ? import ./swiftpm-pins.nix,
  buildLibs,
}:

let
  pins = pinData.deps;
  # One fetch per pinned dependency. fetchSubmodules matches what SwiftPM does
  # when it clones, so the hashes stay comparable to `nurl --submodules=true`.
  checkouts =
    lib.mapAttrs
      (
        _: pin:
        fetchgit {
          inherit (pin) url rev hash;
          fetchSubmodules = true;
        }
      )
      (
        lib.mapAttrs (
          _: pin:
          pin
          // {
            url = pin.location;
            rev = pin.revision;
          }
        ) pins
      );

  # The path dependency resolves inside the unpacked source, so it needs no pin
  # and no entry of its own beyond what SwiftPM writes back itself.
  swiftOpenUIPath = "Vendor/SwiftOpenUI";

  workspaceState = {
    version = 7;
    object = {
      artifacts = [ ];
      prebuilts = [ ];
      dependencies = lib.mapAttrsToList (_: pin: {
        basedOn = null;
        packageRef = {
          inherit (pin) identity name location;
          kind = "remoteSourceControl";
        };
        state = {
          name = "sourceControlCheckout";
          checkoutState = {
            inherit (pin) revision version;
          };
        };
        inherit (pin) subpath;
      }) pins;
    };
  };

  # SwiftPM refuses to build with --disable-automatic-resolution unless the pin
  # file agrees with the manifests, so write the v3 format it expects.
  packageResolved = {
    version = 3;
    inherit (pinData) originHash;
    pins = lib.sortOn (p: p.identity) (
      lib.mapAttrsToList (_: pin: {
        inherit (pin) identity location;
        kind = "remoteSourceControl";
        state = { inherit (pin) revision version; };
      }) pins
    );
  };

  gstPlugins = with gst_all_1; [
    gstreamer
    gstreamer.dev
    gst-plugins-base
    gst-plugins-base.dev
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ];
  desktopItem = makeDesktopItem {
    name = "com.eightybps.Hummingbird";
    desktopName = "Hummingbird";
    exec = "hummingbird-gtk %u";
    terminal = false;
    categories = [ "AudioVideo" "Video" ];
    mimeTypes = [ "x-scheme-handler/com.eightybps.hummingbird" ];
  };
in
stdenv.mkDerivation {
  pname = "hummingbird-gtk";
  inherit version src;

  nativeBuildInputs = [
    swift
    swiftpm
    pkg-config
    makeBinaryWrapper
    # SwiftPM writes caches and config under HOME, and the sandbox's
    # /homeless-shelter is not writable. Not what fixed the offline build --
    # --disable-automatic-resolution below did that -- but it keeps SwiftPM
    # from scribbling outside the build directory.
    writableTmpDirAsHomeHook
    wrapGAppsHook4
  ];

  buildInputs = buildLibs;

  # SwiftPM's system-library importer does not consume pkg-config include
  # flags for transitive C headers. CGStreamer includes these directly.
  CPATH = lib.makeSearchPath "include/gstreamer-1.0" [
    gst_all_1.gstreamer.dev
    gst_all_1.gst-plugins-base.dev
  ];

  # Pre-populate the dependency checkouts so swift-build never reaches the
  # network, which it cannot do inside the sandbox anyway.
  configurePhase = ''
    runHook preConfigure

    mkdir -p .build/checkouts
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: pin: "ln -s ${checkouts.${name}} '.build/checkouts/${pin.subpath}'") pins
    )}

    install -m 0600 ${builtins.toFile "workspace-state.json" (builtins.toJSON workspaceState)} \
      .build/workspace-state.json
    install -m 0600 ${builtins.toFile "Package.resolved" (builtins.toJSON packageResolved)} \
      Package.resolved

    # SwiftPM records the path dependency by absolute path, so it has to be the
    # one in this build's unpacked source rather than whatever resolved last.
    test -e ${swiftOpenUIPath}/Package.swift \
      || { echo "error: ${swiftOpenUIPath} is empty; the flake needs self.submodules" >&2; exit 1; }

    runHook postConfigure
  '';

  # Set by the swiftpm hook; this is the only product we want installed.
  # --disable-automatic-resolution: the pins are already in place, and any
  # attempt to re-resolve would need the network.
  swiftpmFlags = [
    "--product Hummingbird-gtk"
    "--disable-automatic-resolution"
    "--skip-update"
  ];

  # The media backend loads these at run time, and GSK/GdkPixbuf want their own data.
  preFixup = ''
    gappsWrapperArgs+=(
      # Bound reservations, not the general JavaScript heap. These are also
      # inherited by WebKit child processes, including its network process.
      --set-default JSC_structureHeapSizeInKB "262144"
      --set-default JSC_jitMemoryReservationSize "67108864"
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${
        lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gstPlugins
      }"
      --set-default GDK_PIXBUF_MODULE_FILE "${librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
      --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules"
      --prefix XDG_DATA_DIRS : "${adwaita-icon-theme}/share"
    )
  '';

  installPhase = ''
    runHook preInstall

    binPath="$(swiftpmBinPath)"
    mkdir -p $out/libexec/hummingbird $out/bin
    cp "$binPath/Hummingbird-gtk" $out/libexec/hummingbird/
    cp Apps/Linux/Info.json $out/libexec/hummingbird/

    # SwiftPM resource bundles (the plugin prelude, the Material Symbols font)
    # are looked up next to the executable, so they travel with it.
    for bundle in "$binPath"/*.resources; do
      [ -e "$bundle" ] || continue
      cp -r "$bundle" $out/libexec/hummingbird/
    done

    makeWrapper $out/libexec/hummingbird/Hummingbird-gtk $out/bin/hummingbird-gtk
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/*.desktop $out/share/applications/

    runHook postInstall
  '';

  meta = {
    description = "Grayjay-style plugin host, GTK4 build";
    mainProgram = "hummingbird-gtk";
    platforms = lib.platforms.linux;
    license = lib.licenses.agpl3Plus;
  };
}
