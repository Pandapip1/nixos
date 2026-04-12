{
  nixpkgs.overlays = [
    (_: prev: {
      cosmic-ext-pinentry = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "cosmic-ext-pinentry";
        version = "0-unstable-2025-04-11";

        src = prev.fetchFromCodeberg {
          owner = "pandapip1";
          repo = "cosmic-ext-pinentry";
          rev = "661f6e66b88f9d66f95baaf455044cc16ec9112b";
          hash = "sha256-Q/uYy3Lr09braRXgPiGBy/vN/GvdmvlUCXP0ru5XXJw=";
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

        meta.mainProgram = "cosmic-pinentry";
      });
    })
  ];
}
