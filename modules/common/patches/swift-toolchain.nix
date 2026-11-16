{ lib, ... }:

let
  # Every .patch in a directory, in sorted order.
  patchesIn =
    directory:
    lib.pipe (builtins.readDir directory) [
      builtins.attrNames
      (builtins.filter (lib.hasSuffix ".patch"))
      (map (name: directory + "/${name}"))
    ];

  addPatches =
    directory: package:
    package.overrideAttrs (prevAttrs: {
      patches = (prevAttrs.patches or [ ]) ++ patchesIn directory;
    });
in
{
  # Patched inside swiftPackages, so SwiftPM is built against the patched
  # Swift Build, and the top-level swift/swiftpm and swiftpmHook all get them.
  nixpkgs.overlays = [
    (_: prev: {
      swiftPackages = prev.swiftPackages.overrideScope (
        _: sprev: {
          # swift-build/0001: send the build's started and maximum command
          # counts with each started task, which SwiftPM's 0002 needs.
          swift-build = addPatches ./swift-build sprev.swift-build;

          # swiftpm/0001: SwiftPM dropped every flag of a system library
          # target when any package in its Requires.private chain had no .pc
          # file, where pkg-config itself ignores private requirements unless
          # linking statically. Packages using GTK, libadwaita, GStreamer or
          # libsecret needed hand-added .pc stand-ins to build.
          #
          # swiftpm/0002: ninja-style "[started/total] task" progress for
          # every Swift Build task, instead of sampled per-target status.
          swiftpm = addPatches ./swiftpm sprev.swiftpm;
        }
      );
    })
  ];
}
