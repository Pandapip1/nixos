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
      ananicy-rules-cachyos = prev.ananicy-rules-cachyos.overrideAttrs (_: previousAttrs: {
        patches = (previousAttrs.patches or []) ++ [
          ./302f0df848d26456609477c04abd9893941dae28.patch
          ./352c8c1f4323907e73ab45f4ae482dfa713022fd.patch
          ./915a447fe1c8bfe51c4e3f86cf1b34deb195308f.patch
          ./90523aa0717c9335e34b5bf33505b4c40642568c.patch
          ./ef0f2bce3f32cbc503ed401f22c3ff7294113d1d.patch
        ];
      });
    })
  ];
}
