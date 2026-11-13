# The Rust code-signing library (apple-codesign) that swift-rcodesign wraps,
# built from the swift-rcodesign checkout itself. Upstream's Package.swift
# downloads it prebuilt (an artifact bundle); package.nix points that at this.
{
  lib,
  rustPlatform,
  src,
}:

rustPlatform.buildRustPackage {
  pname = "rcodesign-ffi";
  version = "0.2.0";
  inherit src;

  cargoHash = "sha256-/Rz0y/XB0MimII0Vh6DwEF0uDsTXph2bt89p2PtHAoU=";

  # A static library only; there is nothing to run as tests here.
  doCheck = false;

  installPhase = ''
    runHook preInstall
    install -Dm644 -t "$out/lib" target/*/release/librcodesign_ffi.a 2>/dev/null \
      || install -Dm644 -t "$out/lib" target/release/librcodesign_ffi.a
    install -Dm644 -t "$out/include" include/rcodesign.h include/module.modulemap
    runHook postInstall
  '';
}
