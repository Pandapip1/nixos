{ pkgs, ... }:

{
  # nix-darwin links its KeePassXC.app into /Applications/Nix Apps.
  environment.systemPackages = [ pkgs.keepassxc ];
}
