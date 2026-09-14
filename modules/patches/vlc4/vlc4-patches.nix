{ lib, ... }:

let
  # Every .patch in this directory, in sorted order. attrNames sorts, and the
  # files keep their git format-patch numbering, so the series applies in the
  # order it was generated and cannot drift out of step with a hand-kept list.
  patches = lib.pipe (builtins.readDir ./.) [
    builtins.attrNames
    (builtins.filter (lib.hasSuffix ".patch"))
    (map (name: ./. + "/${name}"))
  ];

  # Upstream VLC master that the series was generated against, i.e. the
  # merge-base of our `all-fixes` branch with videolan/master.
  rev = "289a425a89e36f3af8dae040259bbe27dc801b15";
in
{
  nixpkgs.overlays = [
    (final: prev: {
      # nixpkgs only ships the 3.0 series as `vlc`. `vlc_4` is the same
      # derivation re-pointed at 4.0-dev (VLC master) so the 4.0 version of our
      # patch series can be tried without disturbing `vlc`, which stays on
      # 3.0.23 with its own patches from ../vlc.
      #
      # This is `vlc.overrideAttrs` rather than a hand-written derivation on
      # purpose: everything in nixpkgs' vlc that is about *packaging* rather
      # than about 3.0 - the split outputs, strictDeps, BUILDCC for the
      # cross-compiled luac, the freefont path substitution, the plugin cache
      # regeneration, the Qt/GApps double-wrap dance - is still correct for
      # 4.0, and tracking it means nixpkgs' fixes keep arriving. Only the
      # genuinely 3.0-specific parts are replaced below, each one checked
      # against the 4.0 configure.ac.
      vlc_4 = (prev.vlc.override {
        # 4.0 dropped the Qt5 interface entirely; the GUI is Qt6/QML now.
        withQt5 = false;
      }).overrideAttrs
        (prevAttrs: {
          version = "4.0.0-dev-unstable-2026-09-13";

          src = final.fetchFromGitLab {
            domain = "code.videolan.org";
            owner = "videolan";
            repo = "vlc";
            inherit rev;
            hash = "sha256-Y3WUdFkjBUd6thcHeuZKO7pxGnSqAxVkuANQNNvaVUU=";
          };

          # Replaced, not appended: both of nixpkgs' patches are 3.0-only. The
          # live555 LIBADD patch is against 3.0's hand-rolled live555 detection
          # (4.0 uses pkg-config), and deterministic-plugin-cache.diff is the
          # 3.0 backport of a change 4.0 already carries.
          patches = patches;

          # 4.0 removed the Dirac/schroedinger decoder.
          buildInputs =
            (builtins.filter (p: !lib.hasInfix "schroedinger" (p.name or "")) prevAttrs.buildInputs)
            ++ (with final.qt6; [
              qtbase
              # QML runtime for the 4.0 interface: qml, quick, quickcontrols2.
              qtdeclarative
              qtsvg
              # `qsb`, needed to compile the interface's shaders.
              qtshadertools
            ])
            ++ lib.optionals (final.qt6 ? qtwayland) [ final.qt6.qtwayland ];

          # configure locates Qt with qmake6 + modules/gui/qt/scripts/static_dirs.py,
          # so it needs both qmake6 on PATH and a python3. qt6.qmake also brings
          # qtbase's setup hook, which is what points QMAKEPATH at the separate
          # qtdeclarative/qtsvg/qtshadertools store paths.
          nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
            final.qt6.qmake
            final.qt6.wrapQtAppsHook
            final.python3
          ];

          # qt6.qmake's setup hook would otherwise hijack configurePhase.
          dontUseQmakeConfigure = true;

          postFixup = (prevAttrs.postFixup or "") + ''
            remove-references-to -t "${final.qt6.qtbase.dev}" $out/lib/vlc/plugins/gui/libqt_plugin.so
          '';

          meta = prevAttrs.meta // {
            description = "Cross-platform media player and streaming server (4.0 development branch)";
          };
        });
    })
  ];
}
