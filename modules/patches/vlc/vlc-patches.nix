{ lib, ... }:

let
  # Every .patch in this directory, in sorted order. attrNames sorts, and the
  # files keep their git format-patch numbering, so the series applies in the
  # order it was generated and cannot drift out of step with a hand-kept list.
  patches = lib.pipe (builtins.readDir ./.) [
    builtins.attrNames
    (builtins.filter (lib.hasSuffix ".patch"))
    (map (name: ./. + "/${name}"))
  ];
in
{
  nixpkgs.overlays = [
    (_: prev: {
      vlc = prev.vlc.overrideAttrs (prevAttrs: {
        # Sent upstream against 3.0.x. Three groups:
        #
        # 0001-0003 aout. Drift correction in the audio core is applied by
        # resampling, which shifts pitch as well as speed. The accumulated
        # correction was unbounded, was not dropped when it changed direction,
        # and survived a flush or a pause, so a high latency sink - Bluetooth
        # in particular - could leave playback tens of cents sharp for seconds
        # at a time. The 4.0 branch already skips this when the audio clock is
        # the master. Set aout-max-resampling to 0 to never correct drift by
        # resampling at all.
        #
        # 0004-0006 repeat. Seeking was refused once the ogg streams had been
        # torn down at end of stream, so the seek back to the start that
        # repeats a file could never succeed and the input retried it in a
        # tight loop. Repeating now happens in place, which also removes the
        # gap where the audio sink was torn down and rebuilt between plays.
        #
        # 0007-0022 demux. The same class of bug swept across every demuxer:
        # state torn down at end of stream, or a sticky error or eof flag, was
        # not re-established on seek, so a seek after playback finished either
        # failed or read from a half-dismantled demuxer. Two are cherry-picks
        # of existing upstream fixes (webvtt #22448, and the mkv chapter
        # segfault, which master had already fixed by reverting).
        patches = (prevAttrs.patches or [ ]) ++ patches;
      });
    })
  ];
}
