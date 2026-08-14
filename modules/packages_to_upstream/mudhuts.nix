{
  nixpkgs.overlays = [
    (_: prev: {
      mudhuts = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "mudhuts";
        version = "0-unstable-2026-08-14";

        src = prev.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "mudhuts";
          rev = "fc34a1d191c45db90fea41161e300eeef9cd30bc";
          hash = "sha256-ZooM5LlpC/F4jDSJWxpdQEWCd+AFQ1jJb46KO4whoGQ=";
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
