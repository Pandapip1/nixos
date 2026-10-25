{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf
  (
    config.services.graphical-desktop.enable
    && !(config.optimizations.lean.enable)
    # nixpkgs marks swiftc broken on aarch64-linux (gold-linker failure; see
    # pkgs/development/compilers/swift/by-name/sw/swiftc/package.nix), which
    # hummingbird-gtk needs to build. Upstream's own TODO says this is fixed
    # in the Swift 6.4.0 update, so revisit this condition then.
    && !(pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64)
  )
  {
    extraProfiles.singleton.packages = with pkgs; [
      hummingbird-gtk
    ];
  }
