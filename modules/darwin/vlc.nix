{ pkgs, ... }:

let
  # The same patched fork as the NixOS hosts (packages/vlc/fork-src.nix).
  vlc = pkgs.callPackage ../../packages/vlc/darwin.nix {
    inherit (pkgs.callPackage ../../packages/vlc/fork-src.nix { }) version src;
  };
in
{
  # nix-darwin links its VLC.app into /Applications/Nix Apps.
  environment.systemPackages = [ vlc ];
}
