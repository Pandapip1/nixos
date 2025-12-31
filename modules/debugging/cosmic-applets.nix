{
  pkgs,
  ...
}:

let
  inherit (pkgs) lib;
in
{
  nixpkgs.overlays = [
    (_: prev: {
      cosmic-applets = with prev; rustPlatform.buildRustPackage (finalAttrs: {
        pname = "cosmic-applets";
        version = "1.0.0-fixed-icons";

        # nixpkgs-update: no auto update
        src = pkgs.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "cosmic-applets";
          rev = "14deb0d4aad0b8b210f52c48d3b7486f4ff725e1";
          hash = "sha256-KRpaevv4DF32CoZNfhSs6u9WPYNB3n01qpLiZy+CFbU=";
        };

        cargoHash = "sha256-Eq0RSA8TYHKNRx5mg010iyrONigKR0GgGZ3fXnWOmG8=";

        nativeBuildInputs = [
          just
          pkg-config
          util-linuxMinimal
          libcosmicAppHook
          rustPlatform.bindgenHook
        ];

        buildInputs = [
          dbus
          glib
          libinput
          pulseaudio
          pipewire
          udev
        ];

        dontUseJustBuild = true;
        dontUseJustCheck = true;

        justFlags = [
          "--set"
          "prefix"
          (placeholder "out")
          "--set"
          "target"
          "${stdenv.hostPlatform.rust.cargoShortTarget}/release"
        ];

        preFixup = ''
          libcosmicAppWrapperArgs+=(
            --set-default X11_BASE_RULES_XML ${xkeyboard_config}/share/X11/xkb/rules/base.xml
            --set-default X11_EXTRA_RULES_XML ${xkeyboard_config}/share/X11/xkb/rules/base.extras.xml
          )
        '';
      });
    })
  ];
}
