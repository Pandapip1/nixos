# nixos-apple-silicon's uboot-asahi package (apple-silicon-support/packages/uboot-asahi)
# strips the `DTC=...` makeFlag that nixpkgs' generic u-boot builder normally
# passes, so u-boot falls back to building its own vendored, in-tree
# `scripts/dtc` instead of using nixpkgs' host `dtc`. That vendored dtc
# predates the "node_name_not_empty" check that nixpkgs' u-boot builder's
# postPatch now unconditionally rewrites `-Wno-graph_child_address` into
# (to stay compatible with dtc >=1.8's removal of `graph_child_address`),
# so the vendored dtc aborts with:
#   FATAL ERROR: Unrecognized check name "node_name_not_empty"
#
# Put the `DTC=` flag back so the host dtc (1.8.1, which does understand
# `node_name_not_empty`) is used instead of the vendored copy.
#
# nixos-apple-silicon's own module re-applies its base overlay (the one that
# defines `uboot-asahi` from scratch) via `lib.mkBefore`, which empirically
# still lands after plain (unordered) overlays like this one in the final
# merged `nixpkgs.overlays` list -- wiping out an `overrideAttrs` applied at
# normal order. `lib.mkAfter` forces this override to apply last so it
# survives that redefinition.
{
  lib,
  ...
}:

{
  nixpkgs.overlays = lib.mkAfter [
    (final: prev: {
      uboot-asahi = prev.uboot-asahi.overrideAttrs (old: {
        makeFlags = old.makeFlags ++ [ "DTC=${final.lib.getExe final.buildPackages.dtc}" ];
      });
    })
  ];
}
