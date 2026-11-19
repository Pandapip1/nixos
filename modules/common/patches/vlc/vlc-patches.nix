{ ... }:

let
  # The tip of all-fixes-3.0 on the fork. The series used to be exported as a
  # flat patch directory and applied to nixpkgs' 3.0.23 tarball, but the two
  # are not the same source: the fork's base is 3.0.23-2-1253-g1da0650bc4,
  # 1253 commits further along v30x, so every patch was being applied to a
  # tree it was not generated against. `patch` absorbed the drift as line
  # offsets until the ogg rework, whose context had moved too far and which
  # failed outright. Building the branch directly removes the question: what
  # is built here is exactly what was measured there.
in
{
  nixpkgs.overlays = [
    (final: prev: {
      # Gapless and seamless playback work, in eight groups: the audio core's
      # drift correction and its bound; repeating an item in place rather than
      # rebuilding the input; the timestamps a demuxer reports across a seek,
      # for some twenty containers; the packetizers' handling of a break; the
      # pulse output's device latency and startup; the upstream fixes
      # backported alongside them; the dummy output's device simulation; and
      # the tests that hold the lot in place. Each commit on the branch says
      # what it changed and what was measured.
      vlc =
        if (!prev.stdenv.hostPlatform.isDarwin) then
          with prev; vlc.overrideAttrs (prevAttrs: {
            version = "3.0.23-unstable-2026-09-16";

            src = fetchFromGitHub {
              owner = "Pandapip1";
              repo = "vlc";
              rev = "bdd87c95b35570e36da8437a844d5c5020f55005";
              hash = "sha256-8cjtKYO/2SQlJh4BkFYYCpJILVS/BYNFgFfqjo0lnpw=";
            };

            # nixpkgs' own patches stay; ours are in the source now.
            patches = (prevAttrs.patches or [ ]) ++ [
              # Well except this one
              ./qt-macos.patch
            ];
          })
        else
          with final;
          stdenv.mkDerivation (finalAttrs: {
            pname = "vlc";
            version = "3.0.23-unstable-2026-09-16";

            src = fetchFromGitHub {
              owner = "Pandapip1";
              repo = "vlc";
              rev = "bdd87c95b35570e36da8437a844d5c5020f55005";
              hash = "sha256-8cjtKYO/2SQlJh4BkFYYCpJILVS/BYNFgFfqjo0lnpw=";
            };

            # The Qt interface on macOS: quitting deadlocked, and it replaced the
            # app's icon in the Dock (see the patch).
            patches = [ ./qt-macos.patch ];

            nativeBuildInputs = [
              autoreconfHook
              bison
              flex
              lua5_2_compat
              perl
              pkg-config
              unzip
              qt6.wrapQtAppsHook
              # configure finds Qt 6 through qmake; this one knows about every Qt
              # module in the inputs (qtsvg included)
              qt6.qmake
            ];

            buildInputs = [
              faad2
              ffmpeg_8
              flac
              fontconfig
              freetype
              fribidi
              gnutls
              harfbuzz
              libarchive
              libass
              libbluray-full
              libdvbpsi
              libdvdnav
              libdvdnav.libdvdread
              libebml
              libgcrypt
              libgpg-error
              libjpeg
              libmad
              libmatroska
              libmodplug
              libogg
              libopus
              libpng
              librsvg
              libsamplerate
              libssh2
              libtheora
              libvorbis
              libxml2
              lua5_2_compat
              ncurses
              speex
              srt
              taglib_1
              zlib
            ]
            ++ (with qt6; [
              qtbase
              qtsvg
            ])
            # Qt 6 requires at least the macOS 15 SDK.
            ++ [ apple-sdk_15 ];

            strictDeps = true;
            # Keep autotools' configure; qmake is only for the Qt interface, which
            # configure runs itself (the hook still sets QMAKEPATH for it).
            dontUseQmakeConfigure = true;
            enableParallelBuilding = true;
            # bin/Makefile.am renames vlc-osx to vlc in an install-data hook, which a
            # parallel install can run before the program (or even bin/) is installed.
            enableParallelInstalling = false;

            env = {
              # qmake insists on a UTF-8 locale.
              LC_ALL = "en_US.UTF-8";
              # configure fixes C++11 in CXX itself; Qt 6 needs C++17, and CXXFLAGS
              # come later on the command line.
              CXXFLAGS = "-std=c++17 -O2";
              # VLC looks for c11-gcc/c99 by name for build-time helpers.
              BUILDCC = lib.getExe pkgsBuildBuild.stdenv.cc;
              # libvlc and libvlccore identify themselves as @rpath/...; give the
              # installed programs and plugins an rpath to find them.
              NIX_LDFLAGS = "-rpath ${placeholder "out"}/lib";
            };

            postPatch = ''
              echo "$version" > src/revision.txt
              # VLC links its own static contribs on macOS, so configure asks pkg-config
              # for static flags there, dragging in every private dependency (e.g.
              # FFmpeg's encoders). nixpkgs provides shared libraries.
              substituteInPlace configure.ac \
                --replace-fail 'test "''${SYS}" = "mingw32" -o "''${SYS}" = "darwin" -o "''${SYS}" = "os2"' \
                              'test "''${SYS}" = "mingw32" -o "''${SYS}" = "os2"'
            '';

            configureFlags = [
              # Needs ibtool, which only Xcode has; see above.
              "--disable-macosx"
              "--enable-qt"
              # macOS-only extras that fetch or bundle third-party frameworks.
              "--disable-sparkle"
              "--disable-breakpad"
              # Not available on macOS in nixpkgs, or X11-only.
              "--disable-xcb"
              # Qt 6 builds enable VLC's X11 helpers unless X is ruled out.
              "--without-x"
              "--disable-live555"
            ];

            # The qmake hook registers qtbase only; configure's qmake run needs the
            # other Qt modules too.
            preConfigure = ''
              export QMAKEPATH="${lib.getDev qt6.qtsvg}:${qt6.qtsvg}''${QMAKEPATH:+:$QMAKEPATH}"
            '';

            postConfigure = ''
              sed -i 's|^#define CONFIGURE_LINE.*$|#define CONFIGURE_LINE "<removed>"|g' config.h
            '';

            postInstall = ''
              # The macOS launcher (bin/darwinvlc.m) is installed as vlc; make sure.
              if [ ! -e "$out/bin/vlc" ]; then
                (cd bin && ../doltlibtool --mode=install install -c vlc-osx "$out/bin/vlc")
              fi
              # VLC.app is assembled from this by darwin-app.nix, so the bundle (and
              # its icon) can change without rebuilding VLC.
            '';

            # After fixup (stripping changes plugin sizes): the plugin cache is keyed
            # on file mtime and size, so pin the mtimes and generate it last.
            postFixup = ''
              # vlc itself does not link Qt (its Qt interface is a plugin), so the Qt
              # hook leaves it unwrapped and Qt never finds qtsvg's plugins: the
              # interface's SVG icons came out blank. Wrap it explicitly.
              wrapQtApp "$out/bin/vlc"

              find $out/lib/vlc/plugins -exec touch -d @1 '{}' ';'
              $out/lib/vlc/vlc-cache-gen $out/lib/vlc/plugins
            '';

            meta = {
              description = "VLC (patched fork) for macOS, with the Qt interface";
              homepage = "https://github.com/Pandapip1/vlc";
              license = lib.licenses.lgpl21Plus;
              platforms = lib.platforms.darwin;
              mainProgram = "vlc";
            };
          });
      # VLC.app: the VLC build from darwin.nix as a Mac application, kept apart from
      # it so the bundle and its icon can change without rebuilding VLC.
      #
      # The icon is VLC's iOS app icon made into an Icon Composer icon (VLC.icon,
      # see its README), compiled by xtool rather than Apple's actool: a layered icon
      # the system draws with its materials (Liquid Glass) on macOS 26, and an .icns
      # for older systems.
      vlc-app =
        with final;
        stdenvNoCC.mkDerivation {
          pname = "vlc-app";
          inherit (vlc) version;

          dontUnpack = true;
          nativeBuildInputs = [ xtool ];
          # Only xtool's asset compiler is used: the bundle is assembled below rather
          # than built by xtool, and its executable is a shell script, not signed code.
          # xtool's configure phase still keeps its temporary files in the build.
          dontUseXtoolBuild = true;
          dontUseXtoolSign = true;

          installPhase = ''
            runHook preInstall

            app="$out/Applications/VLC.app/Contents"
            mkdir -p "$app/MacOS" "$app/Resources"
            # The icon is named after its file: VLC, not the store path's name.
            cp -r ${./VLC.icon} VLC.icon
            xtool assets compile --output "$app/Resources" --app-icon VLC.icon \
              --minimum-deployment-target 11.0

            cat > "$app/Info.plist" <<'PLIST'
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
              <key>CFBundleExecutable</key><string>VLC</string>
              <key>CFBundleIdentifier</key><string>org.videolan.vlc</string>
              <key>CFBundleName</key><string>VLC</string>
              <key>CFBundleDisplayName</key><string>VLC</string>
              <key>CFBundlePackageType</key><string>APPL</string>
              <key>CFBundleShortVersionString</key><string>${vlc.version}</string>
              <key>CFBundleVersion</key><string>${vlc.version}</string>
              <key>LSMinimumSystemVersion</key><string>11.0</string>
              <key>NSHighResolutionCapable</key><true/>
              <key>CFBundleIconFile</key><string>VLC</string>
              <key>CFBundleIconName</key><string>VLC</string>
            </dict>
            </plist>
            PLIST

            # Started from Finder, open the Qt interface rather than the CLI.
            cat > "$app/MacOS/VLC" <<EOF
            #!/bin/sh
            exec ${vlc}/bin/vlc --intf qt "\$@"
            EOF
            chmod +x "$app/MacOS/VLC"

            # The command-line programs too.
            mkdir -p "$out/bin"
            ln -s ${vlc}/bin/* "$out/bin/"

            runHook postInstall
          '';

          meta = vlc.meta // {
            description = "VLC (patched fork) for macOS, as VLC.app";
          };
        };
      # nixpkgs only ships the 3.0 series as `vlc`. `vlc_4` is the same
      # derivation re-pointed at 4.0-dev (VLC master) so the 4.0 version of our
      # patch series can be tried without disturbing `vlc`, which stays on
      # 3.0.23 with its own patches from ../vlc.
      #
      # This is `vlc.overrideAttrs` rather than a hand-written derivation on
      # purpose: everything in nixpkgs' vlc that is about *packaging* rather
      # than about 3.0 - the split outputs, strictDeps, BUILDCC for the
      # cross-compiled luac, the freefont path substitution, the plugin cache
      # regeneration, the Qt/GApps double-wrap dance - is still correct for
      # 4.0, and tracking it means nixpkgs' fixes keep arriving. Only the
      # genuinely 3.0-specific parts are replaced below, each one checked
      # against the 4.0 configure.ac.
      vlc_4 = with prev;
        (prev.vlc.override {
          # 4.0 dropped the Qt5 interface entirely; the GUI is Qt6/QML now.
          withQt5 = false;
        }).overrideAttrs
          (prevAttrs: {
            version = "4.0.0-dev-unstable-2026-09-13";

            # The tip of all-fixes on the fork, the 4.0 counterpart of the branch ../vlc
            # builds. The series used to be exported as a flat patch directory and
            # applied to the upstream master commit it was branched from; building the
            # branch directly means what is built is exactly what was measured there,
            # with no fuzz and no chance of the two drifting apart.
            src = final.fetchFromGitHub {
              owner = "Pandapip1";
              repo = "vlc";
              rev = "6d0eab81943cc5ae6464a9bab5121fc40bb59476";
              hash = "sha256-Okos4jpMJAK2/B9oydRjt2kfild5dtqVC6TflyN+AEo=";
            };

            # None at all. Ours are in the source now, and nixpkgs' are dropped
            # rather than kept: both are 3.0-only. The live555 LIBADD patch is
            # against 3.0's hand-rolled live555 detection (4.0 uses pkg-config),
            # and deterministic-plugin-cache.diff is the 3.0 backport of a change
            # 4.0 already carries.
            patches = [ ];

            # 4.0 removed the Dirac/schroedinger decoder.
            buildInputs =
              (builtins.filter (p: !lib.hasInfix "schroedinger" (p.name or "")) prevAttrs.buildInputs)
              ++ (with final.qt6; [
                qtbase
                # QML runtime for the 4.0 interface: qml, quick, quickcontrols2.
                qtdeclarative
                qtsvg
                # `qsb`, needed to compile the interface's shaders.
                qtshadertools
              ])
              ++ lib.optionals (final.qt6 ? qtwayland) [ final.qt6.qtwayland ];

            # configure locates Qt with qmake6 + modules/gui/qt/scripts/static_dirs.py,
            # so it needs both qmake6 on PATH and a python3. qt6.qmake also brings
            # qtbase's setup hook, which is what points QMAKEPATH at the separate
            # qtdeclarative/qtsvg/qtshadertools store paths.
            nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
              final.qt6.qmake
              final.qt6.wrapQtAppsHook
              final.python3
            ];

            # qt6.qmake's setup hook would otherwise hijack configurePhase.
            dontUseQmakeConfigure = true;

            postFixup = (prevAttrs.postFixup or "") + ''
              remove-references-to -t "${final.qt6.qtbase.dev}" $out/lib/vlc/plugins/gui/libqt_plugin.so
            '';

            meta = prevAttrs.meta // {
              description = "Cross-platform media player and streaming server (4.0 development branch)";
            };
          });
    })
  ];
}
