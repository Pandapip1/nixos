{
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    (_: prev: {
      ghostty = prev.emptyDirectory;
    })
  ];
}
