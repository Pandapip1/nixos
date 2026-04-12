{
  nixpkgs.overlays = [
    (_: prev: {
      cosmic-ext-pinentry = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "cosmic-ext-pinentry";
        version = "0-unstable-2025-04-11";

        src = prev.fetchFromCodeberg {
          owner = "pandapip1";
          repo = "cosmic-ext-pinentry";
          rev = "4ba4732c6d0a205e0fa54d614ae8e91cb40043de";
          hash = "sha256-cSuZXVfa5216FO7Hi7NFM8xEw+FvIHDrV6cyHQ3XpQc=";
        };
        cargoLock = {
          lockFile = finalAttrs.src + "/Cargo.lock";
          allowBuiltinFetchGit = true;
        };

        postPatch = ''
          substituteInPlace justfile --replace-fail '#!/usr/bin/env' "#!$(command -v env)"
        '';

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

        meta.mainProgram = "cosmic-pinentry";
      });
    })
  ];
}
