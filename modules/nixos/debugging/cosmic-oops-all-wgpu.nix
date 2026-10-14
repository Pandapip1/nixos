{
  nixpkgs.overlays = [
    (final: prev: {
      cosmic-launcher = prev.cosmic-launcher.overrideAttrs (old: {
        buildFeatures = (old.buildFeatures or [ ]) ++ [ "wgpu" ];
      });

      xdg-desktop-portal-cosmic = prev.xdg-desktop-portal-cosmic.overrideAttrs (old: {
        buildFeatures = (old.buildFeatures or [ ]) ++ [ "wgpu" ];
      });
    })
  ];
}
