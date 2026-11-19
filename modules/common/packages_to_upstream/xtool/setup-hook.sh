# shellcheck shell=bash
# Builds a SwiftPM app with xtool when xtool is in nativeBuildInputs, as
# nixpkgs' swiftpmHook does for plain SwiftPM packages:
#   configure  keeps xtool's and SwiftPM's per-user state inside the build
#   build      xtool dev build --configuration $xtoolBuildConfiguration (release)
#              --triple $xtoolTriple $xtoolFlags
#   install    copies xtool/*.app to $out/Applications
#   fixup      re-signs each app bundle ad hoc, since stripping invalidates
#              the linker's signature and Apple Silicon won't run unsigned code
# Each phase is used only if the package doesn't set its own; dontUseXtoolConfigure,
# dontUseXtoolBuild, dontUseXtoolInstall and dontUseXtoolSign turn them off.
# Builds have no network, so SwiftPM never resolves dependencies itself: the
# package puts them in place (e.g. in postConfigure) and they are used as
# pinned.

xtoolConfigurePhase() {
    runHook preConfigure

    # xtool keeps temporary files under the user's caches directory, and
    # SwiftPM its configuration, security and cache directories under the
    # user's home. On macOS both come from the user database, which for a
    # build user is /var/empty.
    export XTL_TMPDIR="$TMPDIR"
    xtoolSwiftPMState="$TMPDIR/xtool-swiftpm"
    mkdir -p "$xtoolSwiftPMState"/{config,security,cache}

    runHook postConfigure
}

xtoolBuildPhase() {
    runHook preBuild

    local flagsArray=(
        --configuration "${xtoolBuildConfiguration:-release}"
        --triple "${xtoolTriple:-arm64-apple-macosx}"
        -Xswiftpm --disable-automatic-resolution
        -Xswiftpm --config-path -Xswiftpm "$xtoolSwiftPMState/config"
        -Xswiftpm --security-path -Xswiftpm "$xtoolSwiftPMState/security"
        -Xswiftpm --cache-path -Xswiftpm "$xtoolSwiftPMState/cache"
    )
    concatTo flagsArray xtoolFlags xtoolFlagsArray
    echoCmd 'xtool build flags' "${flagsArray[@]}"
    # Nix runs builders on a pseudo-terminal with TERM=xterm-256color, so
    # SwiftPM would redraw its progress line in place and the log would keep
    # only the last state. The log can't redraw: with TERM=dumb SwiftPM
    # prints a "[step/total] task" line per step.
    TERM=dumb xtool dev build "${flagsArray[@]}"

    runHook postBuild
}

xtoolInstallPhase() {
    runHook preInstall

    local app found=
    mkdir -p "$out/Applications"
    for app in xtool/*.app; do
        [ -d "$app" ] || continue
        cp -R "$app" "$out/Applications/"
        found=1
    done
    if [ -z "$found" ]; then
        echo "xtoolInstallPhase: xtool built no .app under xtool/" >&2
        exit 1
    fi

    runHook postInstall
}

# Ad hoc, so the code directory, Info.plist and sealed resources form a valid
# signature (unlike re-signing just the executable), and the main executable's
# identifier is the bundle's CFBundleIdentifier.
xtoolSignApps() {
    local app
    for app in "${!outputBin}"/Applications/*.app; do
        [ -d "$app" ] || continue
        echo "xtool: signing $app (ad hoc)"
        @rcodesign@ sign "$app"
    done
}

if [ -z "${dontUseXtoolConfigure-}" ] && [ -z "${configurePhase-}" ]; then
    configurePhase=xtoolConfigurePhase
fi
if [ -z "${dontUseXtoolBuild-}" ] && [ -z "${buildPhase-}" ]; then
    buildPhase=xtoolBuildPhase
fi
if [ -z "${dontUseXtoolInstall-}" ] && [ -z "${installPhase-}" ]; then
    installPhase=xtoolInstallPhase
fi
if [ -z "${dontUseXtoolSign-}" ]; then
    postFixupHooks+=(xtoolSignApps)
fi
