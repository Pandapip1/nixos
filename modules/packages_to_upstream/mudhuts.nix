{
  nixpkgs.overlays = [
    (_: prev: {
      mudhuts = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "mudhuts";
        version = "0-unstable-2026-09-16";

        src = prev.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "mudhuts";
          rev = "aea212e5d9d960bb9919b50bf022ddac9dfe5807";
          hash = "sha256-kY2RVKTkVr/Cp6sDUr5uZsYz1k9Bd5+REh2OpwVX/CE=";
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

        # `mudhuts/src/test_support.rs`'s unit-test harness drives a real
        # in-process xdg_shell client/server handshake over a UnixStream
        # pair — no live compositor/display server needed, but the
        # `wayland-client` crate still `dlopen`s `libwayland-client.so`
        # at runtime rather than linking it at build time, and
        # `buildInputs` alone doesn't put that on the dynamic linker's
        # search path for the check phase's own `cargo test` invocation
        # (only for the final installed binary's rpath, via
        # `autoAddDriverRunpath`/the implicit `buildInputs` rpath). Newer
        # than this package's previous pin — the first build attempt
        # since that harness landed failed 15 tests with
        # `NoWaylandLib`.
        preCheck = ''
          export LD_LIBRARY_PATH="${prev.lib.makeLibraryPath [prev.wayland]}''${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH"
        '';

        postFixup = ''
          patchelf --add-rpath ${prev.libglvnd}/lib $out/bin/mudhuts
        '';

        meta.mainProgram = "mudhuts";
      });
    })
  ];
}
