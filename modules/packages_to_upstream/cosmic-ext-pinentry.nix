{
  nixpkgs.overlays = [
    (_: prev: {
      cosmic-ext-pinentry = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "cosmic-ext-pinentry";
        version = "0-unstable-2025-04-11";

        src = prev.fetchFromCodeberg {
          owner = "pandapip1";
          repo = "cosmic-ext-pinentry";
          rev = "d8bc6418dea4e66935c672d17028714c06d12fee";
          hash = "sha256-cv8X642OBWhxNK3T/ZsxGS3iHb9hVW0dFAuA5XNeySE=";
        };
        cargoLock = {
          lockFile = finalAttrs.src + "/Cargo.lock";
          allowBuiltinFetchGit = true;
        };

        strictDeps = true;
        nativeBuildInputs = with prev; [
          just
          libcosmicAppHook
        ];

        dontUseJustBuild = true;
        dontUseJustCheck = true;

        justFlags = [
          "--set"
          "prefix"
          (placeholder "out")
          "--set"
          "cargo-target-dir"
          "target/${prev.stdenv.hostPlatform.rust.cargoShortTarget}"
        ];

        meta.mainProgram = "cosmic-ext-pinentry";
      });
    })
  ];
}
