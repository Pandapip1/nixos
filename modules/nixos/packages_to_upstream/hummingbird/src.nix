# The Hummingbird revision both the Linux (GTK) and the macOS (SwiftUI) builds
# use; swiftpm-pins.nix must match it.
{ fetchFromGitHub }:

{
  version = "0-unstable-2026-11-12";
  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "Hummingbird";
    rev = "c7bc60dde3b5429340f634c16b7a0e7b7c447b9e";
    hash = "sha256-YjLbc1RJIIptG9pLZxXYwkUUXtSD9kz5WTahLYa4d0I=";
    # Vendor/SwiftOpenUI is a submodule; the builds need its content.
    fetchSubmodules = true;
  };
}
