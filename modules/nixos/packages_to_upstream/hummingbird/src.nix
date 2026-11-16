# The Hummingbird revision both the Linux (GTK) and the macOS (SwiftUI) builds
# use; swiftpm-pins.nix must match it.
{ fetchFromGitHub }:

{
  version = "0-unstable-2026-11-16";
  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "Hummingbird";
    rev = "a1fe07ab1964b137dc0b63732c7844226dbf6ffa";
    hash = "sha256-QSONcOfA0eaKi3O3ecCbFyU6Jqife65oD1yd4r2HISc=";
    # Vendor/SwiftOpenUI is a submodule; the builds need its content.
    fetchSubmodules = true;
  };
}
