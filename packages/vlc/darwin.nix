# The VLC fork (packages/vlc/fork-src.nix) for macOS, with the Qt interface.
#
# nixpkgs' vlc is Linux-only. VLC's own macOS interface (modules/gui/macosx) is
# built from .xib files that only Apple's ibtool (Xcode) can compile, so this
# build uses the Qt interface instead, which VLC supports but turns off by
# default on macOS. It uses Qt 6: nixpkgs' Qt 5 needs a sandbox exception on
# macOS (read access to /usr/share/icu), which the strict sandbox refuses.
# Audio and video output use VLC's macOS modules (auhal, caopengllayer).
# A VLC.app wrapper makes it a normal Mac application.
{
  lib,
  stdenv,
  autoreconfHook,
  bison,
  flex,
  lua5_2_compat,
  perl,
  pkg-config,
  unzip,
  pkgsBuildBuild,
  faad2,
  ffmpeg_8,
  flac,
  fontconfig,
  freetype,
  fribidi,
  gnutls,
  harfbuzz,
  libarchive,
  libass,
  libbluray-full,
  libdvbpsi,
  libdvdnav,
  libebml,
  libgcrypt,
  libgpg-error,
  libjpeg,
  libmad,
  libmatroska,
  libmodplug,
  libogg,
  libopus,
  libpng,
  librsvg,
  libsamplerate,
  libssh2,
  libtheora,
  libvorbis,
  libxml2,
  ncurses,
  speex,
  srt,
  taglib_1,
  zlib,
  qt6,
  apple-sdk_15,
  version,
  src,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "vlc";
  inherit version src;

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

    app="$out/Applications/VLC.app/Contents"
    mkdir -p "$app/MacOS"
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
      <key>CFBundleShortVersionString</key><string>${finalAttrs.version}</string>
      <key>CFBundleVersion</key><string>${finalAttrs.version}</string>
      <key>LSMinimumSystemVersion</key><string>11.0</string>
      <key>NSHighResolutionCapable</key><true/>
    </dict>
    </plist>
    PLIST
    # Started from Finder, open the Qt interface rather than the CLI.
    cat > "$app/MacOS/VLC" <<EOF
    #!/bin/sh
    exec "$out/bin/vlc" --intf qt "\$@"
    EOF
    chmod +x "$app/MacOS/VLC"
  '';

  # After fixup (stripping changes plugin sizes): the plugin cache is keyed
  # on file mtime and size, so pin the mtimes and generate it last.
  postFixup = ''
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
})
