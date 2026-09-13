{ ... }:

{
  nixpkgs.overlays = [
    (_: prev: {
      pipewire = prev.pipewire.overrideAttrs (prevAttrs: {
        # When a process reaches its open file limit the kernel drops the
        # SCM_RIGHTS payload and sets MSG_CTRUNC. PipeWire noticed this but
        # logged it at debug level and returned -EPROTO, so the cause was lost
        # and resurfaced later as an unexplained "can't import mem ... fd:-1".
        # Worse, the failed import errored the core proxy, tearing down every
        # object on that connection - for a session manager, all of its
        # devices. Report the real cause and keep the connection.
        patches = (prevAttrs.patches or [ ]) ++ [
          ./0001-protocol-native-report-dropped-file-descriptors.patch
        ];
      });
    })
  ];
}
