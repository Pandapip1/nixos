# The Hummingbird revision both the Linux (GTK) and the macOS (SwiftUI) builds
# use; swiftpm-pins.nix must match it.
{ fetchFromGitHub }:

{
  version = "0-unstable-2026-11-16";
  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "Hummingbird";
    rev = "13bd2db7b56dbf439ef3bad465e6a411c5bd478d";
    hash = "sha256-UEZux0RuyV0LkvniXTbxwWvwU0GQyxZJ8qhw3UbSKXE=";
    # Vendor/SwiftOpenUI is a submodule; the builds need its content.
    fetchSubmodules = true;
  };
}
