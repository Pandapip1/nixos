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
        inherit (prev.callPackage ./src.nix { }) version src;
        buildLibs = (import ./deps.nix { pkgs = prev; inherit (prev) lib; }).linuxBuildLibs;
      };
    })
  ];
}
