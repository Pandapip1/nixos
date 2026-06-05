{
  nixpkgs.overlays = [
    (final: prev: {
      cosmic-comp = prev.cosmic-comp.overrideAttrs (old: rec {
        src = final.fetchFromGitHub {
          owner = "pop-os";
          repo = "cosmic-comp";
          rev = "1160a3efdd4893e3101bb3de4545c1e10407c6d8";
          hash = "sha256-Brs4TtvavjCT46sKKhgDcCy1nxp8rQ/JzXefSZuTiEQ=";
        };

        cargoDeps = prev.rustPlatform.fetchCargoVendor {
          inherit src;
          lockFile = src + "/Cargo.lock";
          hash = "sha256-ZtC9hwQ8r7W3j30OI4A2cGHMHOVYVe4XYlnSFnAbvRY=";
        };
      });
    })
  ];
}
