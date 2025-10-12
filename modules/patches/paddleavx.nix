{
  nixpkgs.overlays = [
    (_: prev: {
      python312Packages.paddlepaddle = prev.python312Packages.paddlepaddle.overrideAttrs {
        env.WITH_AVX = "OFF";
      };
      python313Packages.paddlepaddle = prev.python313Packages.paddlepaddle.overrideAttrs {
        env.WITH_AVX = "OFF";
      };
    })
  ];
}
