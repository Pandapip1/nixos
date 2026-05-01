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
      plover_5 = prev.plover_5.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or []) ++ [
          (prev.fetchpatch {
            url = "https://github.com/opensteno/plover/commit/b6453858c4bb99ae91ac936074ffec8924a37eac.patch";
          })
        ];

        postPatch = (prev.postPatch or "") + ''
          substituteInPlace setup.cfg \
            --replace-fail \
              "plover              = plover.scripts.main:main" \
              "plover              = plover.scripts.dist_main:main" \
            --replace-fail \
              "plover_plugins      = plover.plugins_manager.__main__:main" \
              "plover_plugins      = plover.scripts.dist_plugins_manager:main"
        '';
      });
    })
  ];
}

