{
  nixpkgs.overlays = [
    (_: prev: {
      cosmic-ext-pinentry = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "cosmic-ext-pinentry";
        version = "0-unstable-2025-04-11";

        src = prev.fetchFromCodeberg {
          owner = "pandapip1";
          repo = "cosmic-ext-pinentry";
          rev = "3371f7a576b238c37c1ad3cc0d9c6b2239b75237";
          hash = "sha256-1zTk7ALiQqd5V8k+sTJBPNJ7U7Q0y4IlEM0WCQsnKxs=";
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
