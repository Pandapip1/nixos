{ ... }:

{
  nixpkgs.overlays = [
    (_: prev: {
      vlc = prev.vlc.overrideAttrs (prevAttrs: {
        # Drift correction in the audio core is applied by resampling, which
        # shifts pitch as well as speed. The accumulated correction was
        # unbounded, was not dropped when it changed direction, and survived a
        # flush or a pause, so a high latency sink - Bluetooth in particular -
        # could leave playback tens of cents sharp for seconds at a time.
        #
        # Upstream 3.0.x; the 4.0 branch already skips this entirely when the
        # audio clock is the master. Set aout-max-resampling to 0 to never
        # correct drift by resampling.
        patches = (prevAttrs.patches or [ ]) ++ [
          ./0001-aout-bound-and-reset-the-drift-correction-resampling.patch
          ./0002-aout-make-the-resampling-bound-configurable.patch
          ./0003-aout-re-establish-the-timing-reference-after-a-flush.patch
        ];
      });
    })
  ];
}
