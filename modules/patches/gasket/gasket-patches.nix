{ ... }:

{
  # gasket_mm_unmap_region() calls zap_vma_ptes(), which mainline renamed to
  # zap_special_vma_range() (David Hildenbrand, "mm: rename zap_vma_ptes() to
  # zap_special_vma_range()", merged into mm-stable 2026-03-29, first shipping
  # in Linux 7.1) - the old name no longer exists on kernels that have this
  # rename, so the gasket (Coral TPU) out-of-tree module fails to build on
  # this host's 7.1.13 kernel. nixpkgs already carries two similar compat
  # patches for this driver (linux-6.12-compat.patch, linux-6.13-compat.patch
  # in pkgs/os-specific/linux/gasket/default.nix) fetched from upstream PRs,
  # but nobody has reported or fixed this particular break on
  # google/gasket-driver yet, so this is our own patch rather than a fetch of
  # an existing upstream commit.
  #
  # `gasket` lives inside `linuxPackagesFor`'s extensible package set (see
  # `boot.kernelPackages.gasket` in nixos/modules/hardware/coral.nix), not at
  # the top level of `pkgs`, so it has to be overridden through
  # `linuxPackagesFor` itself rather than a plain `final: prev: { gasket = ...; }`.
  nixpkgs.overlays = [
    (final: prev: {
      linuxPackagesFor =
        kernel:
        (prev.linuxPackagesFor kernel).extend (
          kfinal: kprev: {
            gasket = kprev.gasket.overrideAttrs (old: {
              patches = (old.patches or [ ]) ++ [
                ./0001-use-zap_special_vma_range-on-kernels-7.1.patch
              ];
            });
          }
        );
    })
  ];
}
