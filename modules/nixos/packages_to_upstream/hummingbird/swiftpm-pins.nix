# SwiftPM dependency pins, mirroring Package.resolved (which is gitignored, so it
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
  # SwiftPM recomputes this from the manifests and re-resolves (i.e. tries to
  # reach the network, which fails in the sandbox) if the pin file disagrees, so
  # it has to match .build/Package.resolved exactly.
  originHash = "db95728f556103d36a335fcaa1e1f0ef63948b821827d179ae05f56f491bfa0d";

  deps = {
    swift-asn1 = {
      subpath = "swift-asn1";
      identity = "swift-asn1";
      name = "swift-asn1";
      location = "https://github.com/apple/swift-asn1.git";
      revision = "3b6410f7dee09eb33cdd26260c5fd47fda19b0e2";
      version = "1.7.3";
      hash = "sha256-Y4MWePdGwLH8wVs9oFnwUUD7YU+WhOnT2rLyxgENIT8=";
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
    swiftsoup = {
      subpath = "SwiftSoup";
      identity = "swiftsoup";
      name = "SwiftSoup";
      location = "https://github.com/scinfu/SwiftSoup.git";
      revision = "18b80329749eca5ea29fc50211dca5c7eff5bfec";
      version = "2.13.9";
      hash = "sha256-2zO+qXO7s6KwPK4BKcon+TgOtjfNicfGHHKHOObP0Uo=";
    };
  };
}
