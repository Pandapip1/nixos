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
          rev = "0cbe59a7c9047c9523ecdabfa80c30588dbbcc61"; # keyboardcontrol-plugins
          hash = "sha256-V6kwGnW97TeaxYGHSlvZ3FoI0KTHzNVGH74BYoHKLWE=";
        };

        buildInputs = prevAttrs.buildInputs ++ (with prev.qt6; [ qtsvg ]);
      });
      python3Packages = prev.python3Packages // {
        plover-plugin-fcitx5-keyboardcontrol = (prev.stdenv.mkDerivation {
          pname = "plover-fcitx5";
          version = "0.1.0-unstable";

          src = prev.fetchFromGitHub {
            owner = "Pandapip1";
            repo = "plover-fcitx5";
            rev = "09338708852beb0e6b2f17dc257dcdbcb908e05f";
            hash = "sha256-tNNj8o6F7J+r/ZtHwmXXJhztjyughOWkg0L9+GLGXqY=";
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
