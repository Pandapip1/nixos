# The Hummingbird revision both the Linux (GTK) and the macOS (SwiftUI) builds
# use; swiftpm-pins.nix must match it.
{ fetchFromGitHub }:

{
  version = "0-unstable-2026-11-16";
  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "Hummingbird";
    rev = "823c5bfe35eae5cd5855913594fd02cae70b1548";
    hash = "sha256-S0a6CUcqIXaaXqcEBj5T9Bj+Y5v24Rp6clJyq6A689c=";
    # Vendor/SwiftOpenUI is a submodule; the builds need its content.
    fetchSubmodules = true;
  };
}
