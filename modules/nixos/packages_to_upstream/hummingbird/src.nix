# The Hummingbird revision both the Linux (GTK) and the macOS (SwiftUI) builds
# use; swiftpm-pins.nix must match it.
{ fetchFromGitHub }:

{
  version = "0-unstable-2026-11-16";
  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "Hummingbird";
    rev = "52f46c8af629d45eccc2ccf9b18d82b4a495a149";
    hash = "sha256-gHoaZD+bfDTSqHmviGfY7bzbyiTZ0tIASCvaSDzhYbY=";
    # Vendor/SwiftOpenUI is a submodule; the builds need its content.
    fetchSubmodules = true;
  };
}
