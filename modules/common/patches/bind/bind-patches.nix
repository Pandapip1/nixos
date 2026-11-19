{
  nixpkgs.overlays = [
    (_: prev: {
      bind = prev.bind.overrideAttrs (prevAttrs: {
        patches = (prevAttrs.patches or [ ]) ++ [
          # ./local-resolver.patch
        ];
      });
    })
  ];
}
