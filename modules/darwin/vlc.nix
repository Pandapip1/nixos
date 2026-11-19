{ pkgs, ... }:

{
  # nix-darwin links its VLC.app into /Applications/Nix Apps.
  environment.systemPackages = [ pkgs.vlc-app ];
}
