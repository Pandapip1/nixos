{
  nixpkgs.overlays = [
    (_: prev: {
      cosmic-ext-pinentry = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "cosmic-ext-pinentry";
        version = "0-unstable-2025-04-11";

        src = prev.fetchFromCodeberg {
          owner = "pandapip1";
          repo = "cosmic-ext-pinentry";
          rev = "1b3ac666e15e339084df64387128d3cf3e44d167";
          hash = "sha256-FE08SxnX9BLSNsj/m5jN8CrS9I6JoFfbTKz6UqOMavY=";
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
