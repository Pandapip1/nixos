{
  nixpkgs.overlays = [
    (final: prev: {
      cosmic-launcher = prev.cosmic-launcher.overrideAttrs (old: rec {
        src = prev.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "cosmic-launcher";
          rev = "0471b2b2f2af646f3ca303a3647d854d7c9369ee";
          hash = "sha256-KLSMIdk5Dkxn6jS6WVLRjbfWCy4Wv3jUG3b+V+9n3lQ=";
        };

        cargoDeps = prev.rustPlatform.fetchCargoVendor {
          inherit src;
          lockFile = src + "/Cargo.lock";
          hash = "sha256-j+pUW/rfqvDL6gxTshsMqF3oiOAC7xS37w0ZWgB4lsY=";
        };
      });
    })
  ];
}
