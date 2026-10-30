# nixpkgs' cosmic-ext-ctl 1.6.0 package tags the fetchFromGitHub src at
# v1.6.0, but upstream forgot to bump the version string embedded in the
# binary via Cargo.toml for that tag -- `cosmic-ctl --version` still prints
# "cosmic-ctl 1.5.0". This trips versionCheckHook's installCheckPhase,
# which compares the derivation's `version` against the binary's reported
# version and fails the build.
#
# Skip the install-time version check for this package rather than waiting
# on upstream/nixpkgs to notice; the built binary is otherwise fine.
{
  nixpkgs.overlays = [
    (_: prev: {
      cosmic-ext-ctl = prev.cosmic-ext-ctl.overrideAttrs (_: {
        doInstallCheck = false;
      });
    })
  ];
}
