{ pkgs, ... }:

let
  # Built from the same pinned revision and SwiftPM pins as the Linux GTK app;
  # see the files in that directory.
  dir = ../nixos/packages_to_upstream/hummingbird;
  hummingbird-macos = pkgs.callPackage (dir + "/hummingbird-macos.nix") {
    inherit (pkgs.callPackage (dir + "/src.nix") { }) version src;
  };
in
{
  # nix-darwin links its Hummingbird.app into /Applications/Nix Apps.
  environment.systemPackages = [ hummingbird-macos ];
}
