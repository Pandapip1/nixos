{
  nixpkgs.overlays = [
    (_: prev: {
      mudhuts = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "mudhuts";
        version = "0-unstable-2026-08-12";

        src = prev.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "mudhuts";
          rev = "461c9dc7da803b6737f003416002dd0414e40e77";
          hash = "sha256-cBXiya35Jam0Bfo+Wvz9tFClN9zVY6dnTD/Lzbv/avc=";
        };
        cargoLock = {
          lockFile = finalAttrs.src + "/Cargo.lock";
          allowBuiltinFetchGit = true;
        };

        strictDeps = true;
        nativeBuildInputs = with prev; [
          pkg-config
          autoAddDriverRunpath
          patchelf
        ];
        buildInputs = with prev; [
          wayland
          wayland-protocols
          libxkbcommon
          libinput
          mesa
          libglvnd
          libgbm
          libdrm
          udev
          seatd
          dbus
          fontconfig
          freetype
          pixman
        ];

        WAYLAND_PROTOCOLS_DIR = "${prev.wayland-protocols}/share/wayland-protocols";

        postFixup = ''
          patchelf --add-rpath ${prev.libglvnd}/lib $out/bin/mudhuts
        '';

        meta.mainProgram = "mudhuts";
      });
    })
  ];
}
