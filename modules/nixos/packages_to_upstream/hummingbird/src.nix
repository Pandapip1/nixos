# The Hummingbird revision both the Linux (GTK) and the macOS (SwiftUI) builds
# use; swiftpm-pins.nix must match it.
{ fetchFromGitHub }:

{
  version = "0-unstable-2026-11-16";
  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "Hummingbird";
    rev = "347e57bb3aee701474d3b6ae2786aa84eba7ae49";
    hash = "sha256-InkUJsh0Wb3JVO1Y5BxwEAaB/bP7IRToAj9K/+HjuoM=";
    # Vendor/SwiftOpenUI is a submodule; the builds need its content.
    fetchSubmodules = true;
  };
}
