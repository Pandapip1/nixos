{
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    (_: prev: {
      ghostty = prev.emptyDirectory // { terminfo = prev.emptyDirectory; };
    })
  ];
}
