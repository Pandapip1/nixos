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
      plover_5 = prev.plover_5.overridePythonAttrs (oldAttrs: {
        verison = "5.3.0";

        src = oldAttrs.src.overrideAttrs {
          rev = "eab1dde8c0283da77603161ead170d4cfa982fe0";
          hash = "sha256-0xes3Tgs39QSUQzV73Ouv7FQIst2u+xIc5X65WkGBkI=";
        };

        postPatch = (oldAttrs.postPatch or "") + ''
          substituteInPlace setup.cfg \
            --replace-fail \
              "plover.scripts.main:main" \
              "plover.scripts.dist_main:main" \
            --replace-fail \
              "plover.plugins_manager.__main__:main" \
              "plover.scripts.dist_plugins_manager:main"
          sed -i 's/xkbcommon<1.1/xkbcommon/g' reqs/dist.txt
        '';

        dependencies = oldAttrs.dependencies ++ (with prev.python3Packages; [
          hidapi
          xkbcommon
        ]);
      });
    })
  ];
}

