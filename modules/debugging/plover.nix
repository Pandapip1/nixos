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
      plover_5 = (prev.plover_5.overridePythonAttrs (oldAttrs: {
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

        disabledTests = [
          # > Command /nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12/bin/python3.13 -m babel.messages.frontend extract --project plover --version 5.3.0 --add-comments i18n: --strip-comments -o /build/tmpnn27ia7o/messages/plover.pot plover failed with output:
          # > /nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12/bin/python3.13: Error while finding module specification for 'babel.messages.frontend' (ModuleNotFoundError: No module named 'babel')
          "test_i18n_files_up_to_date"
        ];
      })).overrideAttrs {
        version = "5.3.0";
        __intentionallyOverridingVersion = true;
      };
    })
  ];
}

