{
  nixpkgs.overlays = [
    (_: prev: {
      initiatarr = rustPlatform.buildRustPackage (finalAttrs: {
        pname = "initiatarr";
        version = "0-unstable-<TODO>";

        src = prev.fetchFromCodeberg {
          owner = "pandapip1";
          repo = "initiatarr";
          rev = "977a4e8d74e12049c5028695880704e83f6cba7c";
        };
        cargoLock.lockFile = finalAttrs.src + "/Cargo.lock";

        strictDeps = true;
        nativeBuildInputs = with prev; [
          pkg-config
        ];
        buildInputs = with prev; [
          openssl
        ];
      })
    })
  ];
}
