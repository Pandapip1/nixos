{
  nixpkgs.overlays = [
    (_: prev: {
      mudhuts = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "mudhuts";
        version = "0-unstable-2026-08-12";

        src = prev.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "mudhuts";
          rev = "51b6f5abf606f1bbd3f2437681148c13ecbf66fc";
          hash = "sha256-wNQ2JckhW6f9XyYjt1BsXUPhIPauaiWeFTik5ttCApc=";
        };
        cargoLock = {
          lockFile = finalAttrs.src + "/Cargo.lock";
          allowBuiltinFetchGit = true;
        };

        strictDeps = true;
        nativeBuildInputs = with prev; [
          pkg-config
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

        meta.mainProgram = "mudhuts";
      });
    })
  ];
}
