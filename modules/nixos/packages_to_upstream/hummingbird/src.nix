# The Hummingbird revision both the Linux (GTK) and the macOS (SwiftUI) builds
# use; swiftpm-pins.nix must match it.
{ fetchFromGitHub }:

{
  version = "0-unstable-2026-11-16";
  src = fetchFromGitHub {
    owner = "Pandapip1";
    repo = "Hummingbird";
    rev = "71f12324c294cf30142cc2e87470b191d6e0b7c4";
    hash = "sha256-a0ZgKd0aXKThciJSNZYmvjb3K/BIeqj+TbvbAXIE/cU=";
    # Vendor/SwiftOpenUI is a submodule; the builds need its content.
    fetchSubmodules = true;
  };
}
