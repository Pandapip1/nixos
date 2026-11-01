{
  nixowos = {
    enable = true;
    # nixowos's overlay patches `fastfetch`, which nixpkgs has since turned
    # into a makeWrapper around fastfetch-unwrapped (so the patch is a no-op),
    # and its patch targets the pre-2.70 logo layout. Patch
    # fastfetch-unwrapped with a port of it instead.
    overlays.fastfetch = false;
  };
  nixpkgs.overlays = [
    (_: prev: {
      fastfetch-unwrapped = prev.fastfetch-unwrapped.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../patches/fastfetch/0001-add-nixowos-logo.patch ];
      });
    })
  ];
  programs.fastfetch.enable = true;
}
