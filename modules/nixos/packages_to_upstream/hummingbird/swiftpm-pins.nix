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
}
