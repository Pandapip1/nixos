{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    attic-client
    btop
    dig
    nixfmt
    poppler-utils
    screen
    tree
  ];
}
