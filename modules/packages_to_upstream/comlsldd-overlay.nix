{
  nixpkgs.overlays = [
    (_: prev: {
      comlsldd =
        with prev;
        (rustPlatform.buildRustPackage (finalAttrs: {
          pname = "comlsldd";
          version = "0-unstable-2026-06-27";

          src = fetchFromCodeberg {
            owner = "Pandapip1";
            repo = "comlsldd";
            rev = "8aeba698ab2e8521a409dd1b6fdbf1cb24e6f666";
            hash = "sha256-FqQLxMIlpIbV12OzhTSyjPSQ+GSgRArQKblP5jUNnLM=";
          };

          cargoHash = "sha256-aaJXJU/WI6FKuOMXIb272Klu4K81+CLQw+EjLjYRPOM=";

          separateDebugInfo = true;
          strictDeps = true;
          __structuredAttrs = true;

          env = {
            LIBRARY_PATH = lib.makeLibraryPath finalAttrs.buildInputs;
            C_INCLUDE_PATH = lib.makeIncludePath finalAttrs.buildInputs;
            LIBCLANG_PATH = lib.makeLibraryPath [ libclang ];
          };

          nativeBuildInputs = [
            cmake
            pkg-config
          ];
          buildInputs = [
            dbus
            liblsl
          ];

          passthru = {
            passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
          };

          meta = {
            homepage = "https://codeberg.org/Pandapip1/comlsldd";
            description = "COMmon LSL Driver Daemon";
            mainProgram = "comlsldd";
            license = lib.licenses.agpl3Plus;
            maintainers = with lib.maintainers; [ pandapip1 ];
            platforms = lib.platforms.all;
          };
        }));
    })
  ];
}
