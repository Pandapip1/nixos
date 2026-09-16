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
        # Sent upstream against 3.0.x. Seven groups:
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
        #
        # 0023-0033 seamless repeat. A repeat tore down and rebuilt the audio
        # output between plays, leaving an audible gap of up to half a second.
        # The output now keeps what it is holding across a repeat, and lateness
        # is skipped rather than flushed.
        #
        # 0034-0037 device latency. The core handed the output its first sample
        # ten milliseconds before it was due, whatever the device needed, so on
        # a sink holding two tenths of a second that sample was born late and
        # the output skipped over the difference - heard as a splice at every
        # start and seek. Outputs can now report what the device adds, and the
        # core gives them that much lead.
        #
        # 0038-0040 drift correction. The bang-bang rule that corrected drift
        # by resampling could not hold the standing offset a device off nominal
        # rate needs, so it hunted. It is now a PI controller bounded in cents,
        # slewed so the noise in the delay an output reports is not turned into
        # pitch wobble. Time scaling was tried instead of resampling to keep
        # the pitch exact, but it splices the waveform every stride whatever
        # the correction size - audible on music, worst in the bass. Two
        # scaletempo bugs found on the way are fixed here: its first stride
        # faded in from the zeroed overlap buffer, and it kept audio across a
        # flush.
        #
        # 0041-0042 seek stale timeline state. A timestamp offset that a seek
        # has to re-establish and does not. ogg carried its chained stream
        # offset into what it reported, walking the reported time past the end
        # of the file on every repeat, and skipped the hold that dates a page
        # whose packets carry no granule, silencing a second at every loop.
        # mkv kept the chapter offset of an ordered edition on the timestamps
        # of whatever non ordered edition was selected after it.
        patches = (prevAttrs.patches or [ ]) ++ patches;
      });
    })
  ];
}
