# `package.nix` is the directory-marker flake.nix's module scanner looks for
# (lib.packagesFromDirectoryRecursive), so this whole directory is imported as
# the single module at this path, and the sibling build files below never get
# collected as their own (invalid) NixOS modules.
#
# hummingbird-gtk.nix/deps.nix/webkitgtk-swift.nix/sysprof-capture-stub.nix/
# swiftpm-pins.nix are Hummingbird's own upstream Nix build
# (github:Pandapip1/Hummingbird, nix/*.nix), copied verbatim rather than
# consumed as a flake input, to match this directory's existing
# fetchFromGitHub-and-build convention (see ../mudhuts.nix, ../comlsldd.nix).
{
  lib,
  ...
}:

{
  nixpkgs.overlays = [
    (_: prev: {
      hummingbird-gtk = prev.callPackage ./hummingbird-gtk.nix {
        version = "0-unstable-2026-10-19";
        src = prev.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "Hummingbird";
          rev = "5182f70fce490ee4f9208d7ccbd2c78f948e33ff";
          hash = "sha256-4hrBjM3YSV6/2k/FLJEJ/ctYd/yEopOsUc6LeMbksYg=";
          # Vendor/SwiftOpenUI is a submodule; the GTK build needs its content.
          fetchSubmodules = true;
        };
        buildLibs = (import ./deps.nix { pkgs = prev; inherit (prev) lib; }).linuxBuildLibs;
      };
    })
  ];
}
