{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf (config.services.graphical-desktop.enable && !(config.optimizations.lean.enable)) {
  extraProfiles.singleton.packages = with pkgs; [
    telegram-desktop
    # Everything below is off for now. The pipewire overlay invalidates their
    # binary-cache substitutes, and the resulting source builds do not fit on
    # ilama. vesktop, caprine, slacky and mattermost-desktop all share the one
    # electron-unwrapped-43.6.0 derivation - Chromium under another name - so a
    # single survivor keeps that build queued; fractal pulls gst-plugins-rs,
    # whose cargo target dir runs to ~40 GiB. Restore the lot once the overlay
    # stops invalidating the cache - see
    # modules/patches/pipewire/pipewire-patches.nix.
    # vesktop
    # caprine
    # slacky
    # fractal # element-desktop
    # mattermost-desktop
  ];
  # Was "needed for vesktop ATM", but vesktop is on electron 43 now, so this
  # pin is stale; it stays commented until something actually asks for it.
  # nixpkgs.config.permittedInsecurePackages = [
  #   "electron-40.10.5"
  # ];
}
