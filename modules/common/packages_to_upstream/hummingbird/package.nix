# `package.nix` is the directory-marker flake.nix's module scanner looks for
# (lib.packagesFromDirectoryRecursive), so this whole directory is imported as
# the single module at this path, and the sibling build files below never get
# collected as their own (invalid) NixOS modules.
#
# hummingbird-gtk.nix/deps.nix/webkitgtk-swift.nix/sysprof-capture-stub.nix/
# swiftpm-pins.nix are Hummingbird's own upstream Nix build
# (github:Pandapip1/Hummingbird, nix/*.nix), copied verbatim rather than
# consumed as a flake input, to match this directory's existing
# fetchFromGitHub-and-build convention (see ../mudhuts.nix, ../comlsldd.nix).
{
  lib,
  ...
}:

{
  nixpkgs.overlays = [
    (
      final: prev:
      let
        pinData = # SwiftPM dependency pins, mirroring Package.resolved (which is gitignored, so it
          # cannot be read from the flake source) and .build/workspace-state.json.
          #
          # nixpkgs' swiftpm2nix helpers are not used: they assert the workspace-state
          # format is version 5 or 6, and SwiftPM 6.2 writes version 7. The generator also
          # assumes every dependency is a git checkout, which is not true here --
          # SwiftOpenUI is a path dependency and comes from the submodule in the source
          # tree, with no revision to pin.
          #
          # To refresh after changing a dependency, run `swift build` and then, for each
          # entry below, read the identity/location/revision/version out of
          # .build/workspace-state.json and get the hash with:
          #
          #   nurl <location> <revision> --json --submodules=true --fetcher=fetchgit
          {
            originHash = "c9e9bf887623a73593611384b2e1272e0e5d1efadc40e946523f5bd336ed3f2f";
            deps = {
              swift-asn1 = {
                subpath = "swift-asn1";
                identity = "swift-asn1";
                name = "swift-asn1";
                location = "https://github.com/apple/swift-asn1.git";
                revision = "917b472dbe53ba699cbb0495f9a95a084bc6364d";
                version = "1.7.4";
                hash = "sha256-oCy/c6UXUgM/dLf054kvkOtVtUXMCdFDRJwWIfhdlGc=";
              };
              swift-atomics = {
                subpath = "swift-atomics";
                identity = "swift-atomics";
                name = "swift-atomics";
                location = "https://github.com/apple/swift-atomics.git";
                revision = "0442cb5a3f98ab802acb777929fdb446bda11a34";
                version = "1.3.1";
                hash = "sha256-ltWzlf0+XxMCR9xiFVGnQ35DueAp22mPRLadbTfnEPA=";
              };
              swift-collections = {
                subpath = "swift-collections";
                identity = "swift-collections";
                name = "swift-collections";
                location = "https://github.com/apple/swift-collections.git";
                revision = "88754449ab766a739610b660e117762115fabc9c";
                version = "1.7.6";
                hash = "sha256-uqToq9UXZn9no3JaWuF3/ouClG1r0f02mFnayWdqk0Y=";
              };
              swift-crypto = {
                subpath = "swift-crypto";
                identity = "swift-crypto";
                name = "swift-crypto";
                location = "https://github.com/apple/swift-crypto.git";
                revision = "95ba0316a9b733e92bb6b071255ff46263bbe7dc";
                version = "3.15.1";
                hash = "sha256-RzoUBx4l12v0ZamSIAEpHHCRQXxJkXJCwVBEj7Qwg9I=";
              };
              swift-nio = {
                subpath = "swift-nio";
                identity = "swift-nio";
                name = "swift-nio";
                location = "https://github.com/apple/swift-nio.git";
                revision = "2f58d8ef84438d6517fc78bcea2f8527e3c72936";
                version = "2.105.0";
                hash = "sha256-yrvHFodrFofHfh2PZ2O+/Guqq9dVEDpPAYoNwcOk9eY=";
              };
              swift-qrcode-generator = {
                subpath = "swift-qrcode-generator";
                identity = "swift-qrcode-generator";
                name = "swift-qrcode-generator";
                location = "https://github.com/fwcd/swift-qrcode-generator.git";
                revision = "5ca09b6a2ad190f94aa3d6ddef45b187f8c0343b";
                version = "1.0.3";
                hash = "sha256-WTIn+AYbazzU5xr78H43Pp1OQYmTp9IkTvezBaiXm9M=";
              };
              swift-system = {
                subpath = "swift-system";
                identity = "swift-system";
                name = "swift-system";
                location = "https://github.com/apple/swift-system.git";
                revision = "869129b7bf4ecc57b97d0193ad29690ca2134750";
                version = "1.8.1";
                hash = "sha256-mnQcCHYW0oCadmIE9ayjs3aZiCVQRuliQ0qWpQ22OFQ=";
              };
              swiftsoup = {
                subpath = "SwiftSoup";
                identity = "swiftsoup";
                name = "SwiftSoup";
                location = "https://github.com/scinfu/SwiftSoup.git";
                revision = "e7f85f4d3dd91ca9a1e94d3328aa1ed5120a8c0f";
                version = "2.14.3";
                hash = "sha256-EFgzS4Lr3vAKMt/kRaMrSqezCTlFe7MTGM3o3nFzzp4=";
              };
            };
          };
        pins = pinData.deps;
        # One fetch per pinned dependency. fetchSubmodules matches what SwiftPM does
        # when it clones, so the hashes stay comparable to `nurl --submodules=true`.
        checkouts =
          lib.mapAttrs
            (
              _: pin:
              final.fetchgit {
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

        desktopItem = final.makeDesktopItem {
          name = "com.eightybps.hummingbird";
          desktopName = "Hummingbird";
          exec = "hummingbird-gtk %u";
          terminal = false;
          categories = [
            "AudioVideo"
            "Video"
          ];
          mimeTypes = [ "x-scheme-handler/com.eightybps.hummingbird" ];
        };
        # The system libraries the SwiftPM build needs, shared by the dev shell and the
        # packaged GTK app so the two cannot drift.
        inherit (final) pkgs lib;
        webkitGTK = final.webkitgtk-swift-compatible;
        # The direct media backend decodes through GStreamer, so these are needed at run time (on
        # GST_PLUGIN_SYSTEM_PATH_1_0), not just at link time.
        gstPlugins = with pkgs.gst_all_1; [
          gstreamer
          gstreamer.dev
          gst-plugins-base
          gst-plugins-base.dev
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav
          # Provides gtk4paintablesink with GL texture / DMA-BUF import support.
          # The backend falls back to appsink on hosts without a usable GTK GL context.
          gst-plugins-rs
        ];
        # The full gst-plugins-bad directory hangs GStreamer's Darwin plugin scanner.
        # Hummingbird only needs its HLS demuxer, so expose that plugin on its own.
        darwinGstHLS =
          pkgs.runCommand "gstreamer-hls-plugin-${pkgs.gst_all_1.gst-plugins-bad.version}" { }
            ''
              mkdir -p "$out/lib/gstreamer-1.0"
              ln -s "${pkgs.gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0/libgsthls.dylib" \
                "$out/lib/gstreamer-1.0/libgsthls.dylib"
            '';
        darwinGstPlugins = with pkgs.gst_all_1; [
          gstreamer
          gstreamer.dev
          gst-plugins-base
          gst-plugins-base.dev
          gst-plugins-good
          gst-libav
          darwinGstHLS
        ];
        iconTheme = pkgs.adwaita-icon-theme;

        # Used by HummingbirdKit, SwiftSoup on every platform.
        baseLibs = with pkgs; [
          zlib
          libxml2
          curl
          sqlite
        ];

        # What the SwiftOpenUI GTK4 backend resolves through pkg-config.
        gtkLibs =
          (with pkgs; [
            gtk4
            libadwaita
            appstream
            glib
            glib-networking # GIO TLS backend used by WebKitGTK/libsoup for HTTPS
            cairo
            pango
            gdk-pixbuf
            graphene
            harfbuzz
            fontconfig
            freetype
            libepoxy
            librsvg # gdk-pixbuf SVG loader, for icon assets
            webkitGTK # WebKitGTK 6 with upstream ICU routed to private ELF sonames
            libsoup_3 # WebKitGTK's public pkg-config dependency
            libsecret # Security.framework-compatible credential persistence
            libsodium # SwiftOpenUI SecureBytes: guarded, mlock'd secret memory (no Requires)
            avahi-compat # dns_sd.h/libdns_sd for ATAppSync DNS-SD discovery
          ])
          ++ gstPlugins
          ++ [
            iconTheme # standard GTK icons in minimal/package-only sessions
          ];

        # Development-only GTK backend on macOS. WebKitGTK is intentionally absent:
        # nixpkgs marks it broken on Darwin, and SwiftOpenUI excludes that adapter.
        darwinGtkLibs =
          (with pkgs; [
            gtk4
            libadwaita
            appstream
            glib
            glib-networking # GIO TLS backend used by GStreamer's libsoup source
            pcre2
            cairo
            pango
            gdk-pixbuf
            graphene
            harfbuzz
            fribidi
            libthai
            libdatrie
            fontconfig
            freetype
            libepoxy
            libxdmcp
            librsvg
            iconTheme
            (# nixpkgs' glib-2.0.pc and gio-2.0.pc carry `Requires.private: sysprof-capture-4`,
# but no nixpkgs package installs a sysprof-capture-4.pc (sysprof ships
# sysprof-6.pc, and the capture library itself is built into glib). The real
# pkg-config binary only resolves private requires for --static, so GTK builds
# normally never notice.
#
# SwiftPM does not shell out to pkg-config: it parses .pc files itself and always
# walks the private chain. One unresolvable entry makes it drop *every* flag for
# the module, so `import CGTK` fails with "'gtk/gtk.h' file not found" and only a
# "couldn't find pc file for sysprof-capture-4" warning to explain it.
#
# This stub satisfies the chain. It is correct for the dynamic link Hummingbird
# does: the capture symbols already live inside libglib-2.0.so, so there is
# nothing extra to add to cflags or libs.
{ writeTextDir }:
writeTextDir "lib/pkgconfig/sysprof-capture-4.pc" ''
  Name: sysprof-capture-4
  Description: Stub satisfying glib's Requires.private (see nix/sysprof-capture-stub.nix)
  Version: 3.38.0
  Cflags:
  Libs:
'')
          ])
          ++ darwinGstPlugins;
      in
      {
        hummingbird-gtk = final.stdenv.mkDerivation {
          pname = "hummingbird-gtk";
  version = "0-unstable-2026-11-16";
  src = final.fetchFromGitHub {
    owner = "Pandapip1";
    repo = "Hummingbird";
    rev = "694566cd6f74de7914b39a15573ea5e9efed63df";
    hash = "sha256-rQF5HIZTNt9X/B86rr3aKkLUUEHRW9Iin3XTa6ek8/U=";
    # Vendor/SwiftOpenUI is a submodule; the builds need its content.
    fetchSubmodules = true;
  };

          nativeBuildInputs = with final; [
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

          buildInputs = baseLibs ++ gtkLibs;

          # SwiftPM's system-library importer does not consume pkg-config include
          # flags for transitive C headers. CGStreamer includes these directly.
          CPATH = lib.makeSearchPath "include/gstreamer-1.0" (with final; [
            gst_all_1.gstreamer.dev
            gst_all_1.gst-plugins-base.dev
          ]);

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
          ];

          # Nix runs builders on a pseudo-terminal with TERM=xterm-256color, so
          # SwiftPM would redraw its progress line in place and the log would keep
          # only the last state. The log can't redraw: with TERM=dumb SwiftPM prints
          # a "[step/total] task" line per step.
          preBuild = ''
            export TERM=dumb
          '';

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
              --set-default GDK_PIXBUF_MODULE_FILE "${final.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
              --prefix GIO_EXTRA_MODULES : "${final.glib-networking}/lib/gio/modules"
              --prefix XDG_DATA_DIRS : "${final.adwaita-icon-theme}/share"
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
        };
        hummingbird-macos = final.stdenv.mkDerivation {
          pname = "hummingbird-macos";
  version = "0-unstable-2026-11-16";
  src = final.fetchFromGitHub {
    owner = "Pandapip1";
    repo = "Hummingbird";
    rev = "694566cd6f74de7914b39a15573ea5e9efed63df";
    hash = "sha256-rQF5HIZTNt9X/B86rr3aKkLUUEHRW9Iin3XTa6ek8/U=";
    # Vendor/SwiftOpenUI is a submodule; the builds need its content.
    fetchSubmodules = true;
  };

          nativeBuildInputs = with final; [
            xtool
            swift
            swiftpm
            writableTmpDirAsHomeHook
          ];

          # The macOS 26 SDK: the newest whose SwiftUI @State is still a plain property
          # wrapper. From 27 it is a macro whose implementation (SwiftUIMacros) is a
          # closed compiler plugin that ships only with Xcode. The app also uses
          # macOS 26 APIs (glassEffect, ToolbarSpacer), so 15 is too old.
          buildInputs = with final; [
            apple-sdk_26
            # Hummingbird's minimum (Package.swift platforms: macOS 15). Without it
            # nixpkgs' compiler wrapper builds for its own default, 14.0.
            (darwinMinVersionHook "15.0")
            # nixpkgs' SDK leaves out headers of libraries nixpkgs provides itself
            sqlite
          ];

          postConfigure = ''
            ${pinData.deps.configure}
            # The newest SDK among the inputs normally wins, and nixpkgs' Swift brings
            # the 27 SDK along; select 26 explicitly (xtool keeps SDKROOT).
            export DEVELOPER_DIR=${final.apple-sdk_26}
            export SDKROOT=${final.apple-sdk_26.sdkroot}
            # sqlite3.h and libsqlite3, for Hummingbird's CSQLite module. xtool runs
            # SwiftPM itself, so these go through clang's environment, not flags.
            export CPATH=${lib.getDev final.sqlite}/include''${CPATH:+:$CPATH}
            export LIBRARY_PATH=${lib.getLib final.sqlite}/lib''${LIBRARY_PATH:+:$LIBRARY_PATH}
            # xtool's default is Swift Build; the native build system is used here.
            export XTOOL_BUILD_SYSTEM=native
          '';

          meta = {
            description = "Hummingbird, the native SwiftUI app for macOS";
            platforms = final.lib.platforms.darwin;
            mainProgram = "Hummingbird";
          };
        };
      }
    )
  ];
}
