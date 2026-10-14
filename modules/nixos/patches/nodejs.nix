{ ... }:

{
  # nodejs-slim_26's `test-ci-js` checkTarget fails inside the Nix build
  # sandbox: parallel/test-fs-cp-async-file-modes.mjs does chmod(..., suid)
  # and gets EPERM, since the sandbox doesn't grant the build user permission
  # to set the setuid bit. nixpkgs already skips this checkTarget on Darwin
  # for the same class of sandbox restriction (see nodejs.nix's comment on
  # `test-ci-js`) but not on Linux, so it surfaces here instead. This pulls
  # in nodejs_latest (= nodejs_26), which llama-cpp (modules/patches/llama-cpp.nix)
  # depends on for its webui build, so the failure was cascading into the
  # whole system closure.
  nixpkgs.overlays = [
    (_: prev: {
      nodejs-slim_26 = prev.nodejs-slim_26.overrideAttrs (_: {
        doCheck = false;
      });
    })
  ];
}
