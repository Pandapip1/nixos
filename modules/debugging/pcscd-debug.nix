{
  nixpkgs.overlays = [
    (final: prev: {
      pcsclite = prev.enableDebugging prev.pcsclite;
      pcscliteWithPolkit = prev.enableDebugging prev.pcscliteWithPolkit;
    })
  ];
}
