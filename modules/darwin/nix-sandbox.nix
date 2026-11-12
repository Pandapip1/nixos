{
  # Nix leaves the build sandbox off by default on macOS. Turn it on so builds
  # here can't read the rest of the filesystem or reach the network unless the
  # derivation is fixed-output, as on NixOS.
  nix.settings.sandbox = true;
}
