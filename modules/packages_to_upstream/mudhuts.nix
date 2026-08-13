{
  nixpkgs.overlays = [
    (_: prev: {
      mudhuts = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "mudhuts";
        version = "0-unstable-2026-08-12";

        src = prev.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "mudhuts";
          rev = "9a91518a2d84c5c5200561504f6574d1bd0918c7";
          hash = "sha256-ukIKrieyV93q7kxCbX0LqmtNWUZX4hBesKWvE3XaE9o=";
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
