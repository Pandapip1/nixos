{
  nixpkgs.overlays = [
    (final: prev: {
      # https://github.com/NixOS/nixpkgs/issues/536623#issuecomment-4833056236
      vesktop = prev.vesktop.override {
        pnpm_10_29_2 = final.pnpm_10;
      };
    })
  ];
}
