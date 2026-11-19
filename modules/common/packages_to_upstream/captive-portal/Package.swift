// swift-tools-version:5.9
import PackageDescription

// One small window for logging in to captive portals. It uses each platform's
// own WebKit (WKWebView on macOS, WebKitGTK on Linux) and loads everything
// through the SOCKS proxy that captive-browser starts, which resolves names
// with the network's own DNS server instead of the local resolver.

#if os(Linux)
let platformTargets: [Target] = [
    // Compiler and linker flags come from pkg-config in the Nix build (see
    // package.nix); SwiftPM's own .pc parsing needs every transitive
    // Requires.private file to be present.
    .systemLibrary(name: "CWebKitGTK")
]
let platformDependencies: [Target.Dependency] = ["CWebKitGTK"]
#else
let platformTargets: [Target] = []
let platformDependencies: [Target.Dependency] = []
#endif

let package = Package(
    name: "captive-portal",
    platforms: [.macOS(.v14)],
    targets: platformTargets + [
        .executableTarget(name: "captive-portal", dependencies: platformDependencies)
    ]
)
