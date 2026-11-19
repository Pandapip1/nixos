{
  nixpkgs.overlays = [
    (_: prev: {

      # vzvm with a "unixgram" network mode, so the guest's network can come from
      # gvproxy instead of Virtualization.framework's NAT (see below).
      vzvm = prev.vzvm.overrideAttrs (prevAttrs: {
        patches = (prevAttrs.patches or [ ]) ++ [
          ./0001-Let-the-guest-network-use-a-user-mode-stack-instead-.patch
        ];
        # The package builds from the repository's vzvm/ directory; the patch's
        # paths start at the repository root.
        patchFlags = [ "-p2" ];
      });
    })
  ];
}
