{ pkgs, ... }:

{
  # nix-darwin links its Hummingbird.app into /Applications/Nix Apps.
  environment.systemPackages = with pkgs; [ hummingbird-macos ];
}
