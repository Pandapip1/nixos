{
  nixpkgs.overlays = [
    (_: prev: {
      mudhuts = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "mudhuts";
        version = "0-unstable-2026-08-14";

        src = prev.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "mudhuts";
          rev = "686648bd689d9ab8bf40a12609dfd03f9b280904";
          hash = "sha256-5DQCQATLyl8f5WjEa2nrqhSLvFLAePKNG4uMJ8mIIjY=";
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
          # `libspa-sys` (part of `mudhuts-portal`'s `pipewire` dependency,
          # for its ScreenCast backend) uses `bindgen` to generate FFI
          # bindings from PipeWire/SPA's C headers at build time — this is
          # nixpkgs' standard hook for that, setting up `LIBCLANG_PATH`
          # and `BINDGEN_EXTRA_CLANG_ARGS` (glibc's own include path) so
          # clang can find both libclang itself and the standard C
          # headers it needs to parse the wrapper header.
          rustPlatform.bindgenHook
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
          pipewire
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
