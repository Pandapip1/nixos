{
  nixpkgs.overlays = [
    (_: prev: {
      mudhuts = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "mudhuts";
        version = "0-unstable-2026-08-12";

        src = prev.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "mudhuts";
          rev = "fc128e8d407b79a57eb0f9dcd33e53d4045107a5";
          hash = "sha256-tcfD7shdtT+MMI1SqRVHrq1lCiaIpU40rBdG1dz1tQY=";
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
