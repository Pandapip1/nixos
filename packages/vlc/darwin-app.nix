# VLC.app: the VLC build from darwin.nix as a Mac application, kept apart from
# it so the bundle and its icon can change without rebuilding VLC.
#
# The icon is VLC's iOS app icon made into an Icon Composer icon (VLC.icon,
# see its README), compiled by xtool rather than Apple's actool: a layered icon
# the system draws with its materials (Liquid Glass) on macOS 26, and an .icns
# for older systems.
{
  lib,
  stdenvNoCC,
  callPackage,
  vlc,
  xtool ? callPackage ../xtool/package.nix { },
}:

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
}
