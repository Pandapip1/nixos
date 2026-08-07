{
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    (_: prev: {
      plover_5 = prev.plover.overrideAttrs (prevAttrs: {
        src = prev.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "plover";
          rev = "9954fd70aaed3d0be6432f77e1111b8474ef48cf"; # keyboardcontrol-plugins
          hash = "sha256-OPG58zqOWoLge5I4a7zE4L2Kqi8VOELroEvGOOzn88c=";
        };

        buildInputs = prevAttrs.buildInputs ++ (with prev.qt6; [ qtsvg ]);
      });
      python3Packages = prev.python3Packages // {
        plover-plugin-fcitx5-keyboardcontrol = (prev.stdenv.mkDerivation {
          pname = "fcitx5-plover";
          version = "0.1.0";

          src = prev.fetchFromGitHub {
            owner = "Pandapip1";
            repo = "plover-plugin-fcitx5-keyboardcontrol";
            rev = "aa29e45c2ec4b902fef51318c0eeb36c952ac058";
            hash = "sha256-qFCoQvphvN6Hyys8q8h3C5DQfc78/K28f5reyU8HVTE=";
          };

          nativeBuildInputs = [
            prev.cmake
            prev.kdePackages.extra-cmake-modules
            prev.python3Packages.python
            prev.python3Packages.pip
            prev.python3Packages.setuptools
            prev.python3Packages.wheel
            prev.python3Packages.pybind11
          ];

          buildInputs = [
            prev.kdePackages.extra-cmake-modules
            prev.fcitx5
          ];

          __structuredAttrs = true;
          strictDeps = true;
          seperateDebugInfo = true;

          meta = {
            description = "fcitx5 keyboard control backend for Plover, and its matching fcitx5 addon";
            homepage = "https://github.com/openstenoproject/plover-plugin-fcitx5-keyboardcontrol";
            license = lib.licenses.gpl3Plus;
            platforms = lib.platforms.linux;
          };
        });
      };
    })
  ];
}
