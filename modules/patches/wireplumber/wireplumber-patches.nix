{ ... }:

{
  nixpkgs.overlays = [
    (_: prev: {
      wireplumber = prev.wireplumber.overrideAttrs (prevAttrs: {
        # core_error() acted on id 0 with -EPIPE and silently discarded every
        # other error, so server side failures were invisible from the session
        # manager's side: objects would stop working with nothing logged here.
        patches = (prevAttrs.patches or [ ]) ++ [
          ./0001-core-report-core-errors-instead-of-discarding-them.patch
        ];
      });
    })
  ];
}
