# The Hummingbird revision both the Linux (GTK) and the macOS (SwiftUI) builds
# use; swiftpm-pins.nix must match it.
{ fetchFromGitHub }:

{
  version = "0-unstable-2026-11-16";
  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "Hummingbird";
    rev = "0c1ae16a4f3dd03050cefeb7bd62a858a6fa6c03";
    hash = "sha256-P3Nep7kWXeg/zCMhQx41/RvGEu7o1Z3E2QLVdq4iTow=";
    # Vendor/SwiftOpenUI is a submodule; the builds need its content.
    fetchSubmodules = true;
  };
}
