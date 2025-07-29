{
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    (_: prev: {
      inputplumber = prev.callPackage (
        {
          lib,
          rustPlatform,
          fetchFromGitHub,
          pkg-config,
          udev,
          libiio,
          libevdev,
        }:

        rustPlatform.buildRustPackage rec {
          pname = "inputplumber";
          version = "0.60.8";

          src = fetchFromGitHub {
            owner = "ShadowBlip";
            repo = "InputPlumber";
            rev = "97b2f8ebf5c14f9a29b5d283d4cdb0b2192fdef2";
            hash = "sha256-xgP5EsTPt5mVUBs7vRpRionophQ8oPkXjbRU0CI0HOs=";
          };

          useFetchCargoVendor = true;
          cargoHash = "sha256-i9mFQ12z3YE6Kb89Tt27reG1Y3rUmzTkAlT4Zd8rgXg=";

          nativeBuildInputs = [
            pkg-config
            rustPlatform.bindgenHook
          ];

          buildInputs = [
            udev
            libevdev
            libiio
          ];

          postInstall = ''
            cp -r rootfs/usr/* $out/
          '';

          meta = {
            description = "Open source input router and remapper daemon for Linux";
            homepage = "https://github.com/ShadowBlip/InputPlumber";
            license = lib.licenses.gpl3Plus;
            changelog = "https://github.com/ShadowBlip/InputPlumber/releases/tag/v${version}";
            maintainers = with lib.maintainers; [ shadowapex ];
            mainProgram = "inputplumber";
          };
        }
      ) { };
    })
  ];
}
