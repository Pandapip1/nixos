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
          version = "0.62.0";

          src = fetchFromGitHub {
            owner = "ShadowBlip";
            repo = "InputPlumber";
            rev = "c2b69595480fa3e99e41879e98eada9c80f93540";
            hash = "sha256-j3zJ9VLSRKkMYirME3Sf/xGn/j4GRj+mnR4yOJvyPLg=";
          };

          cargoHash = "sha256-y2IHH8eqbi+suF2kx6vf4SEQNSJiU/p5KEsaemnzYE0=";

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
