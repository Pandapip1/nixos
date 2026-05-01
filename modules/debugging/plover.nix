{
  pkgs,
  ...
}:

let
  inherit (pkgs) lib;
in
{
  nixpkgs.overlays = [
    (_: prev: {
      plover_5 = plover_5.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or []) ++ prev.fetchPatch {
          url = "https://github.com/opensteno/plover/commit/b6453858c4bb99ae91ac936074ffec8924a37eac.patch";
        };
      });
    })
  ];
}

