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
      pipewire = prev.pipewire.overrideAttrs (prevAttrs: {
        # 0001 protocol-native. When a process reaches its open file limit the
        # kernel drops the SCM_RIGHTS payload and sets MSG_CTRUNC. PipeWire
        # noticed this but logged it at debug level and returned -EPROTO, so
        # the cause was lost and resurfaced later as an unexplained "can't
        # import mem ... fd:-1". Worse, the failed import errored the core
        # proxy, tearing down every object on that connection - for a session
        # manager, all of its devices. Report the real cause and keep the
        # connection.
        #
        # 0002-0003 bluez5. The A2DP sample rate was picked from a global
        # preference, so a headset that only sounds right at 44100 could not be
        # accommodated without forcing every other device to the same rate.
        # Make the preferred rate a per-device setting, exposed through the
        # generic audio.rate property: settable as a device property, or at
        # runtime with
        #   pw-cli set-param <id> Props '{ params = [ "audio.rate", 44100 ] }'
        # The device also lists the rates its selected codec can actually use.
        #
        # 0004 pulse-server. Sink and source info carried a hardcoded zero
        # latency, so every device looked free even when it was not: the A2DP
        # sink reports 214 ms through SPA_PARAM_Latency and clients were told
        # 0. A client then has to start a stream and read sink_usec back to
        # learn what the device costs, by which point it has already begun
        # playing on the wrong figure.
        patches = (prevAttrs.patches or [ ]) ++ patches;
      });
    })
  ];
}
