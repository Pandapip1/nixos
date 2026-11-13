# Sets up a SwiftPM package's dependencies from pins (identity, name,
# location, revision, version, subpath, hash per dependency) so it builds
# offline: each dependency is a fetchgit checkout, linked into
# .build/checkouts with the workspace-state.json and Package.resolved SwiftPM
# would have written after resolving them itself.
#
# nixpkgs' swiftpm2nix is not used: it asserts workspace-state version 5 or 6,
# and SwiftPM 6.2 and later write version 7.
#
#   deps = callPackage ./swiftpm-deps.nix { } {
#     pinData = import ./swiftpm-pins.nix;
#     # Optional: replace a checkout, e.g. to patch its manifest.
#     overrides = { some-dep = checkout: patchedCopyOf checkout; };
#   };
#   ... configurePhase = deps.configure; ...
{
  lib,
  fetchgit,
}:

{
  pinData,
  overrides ? { },
  # Where SwiftPM keeps its state: .build, or a package's --scratch-path.
  scratchPath ? ".build",
  # Where Package.resolved goes: the package's root.
  packageRoot ? ".",
}:

let
  pins = pinData.deps;
  checkouts = lib.mapAttrs (
    name: pin:
    (overrides.${name} or lib.id) (fetchgit {
      url = pin.location;
      rev = pin.revision;
      inherit (pin) hash;
      fetchSubmodules = true;
    })
  ) pins;

  workspaceState = {
    version = 7;
    object = {
      artifacts = [ ];
      prebuilts = [ ];
      dependencies = lib.mapAttrsToList (_: pin: {
        basedOn = null;
        packageRef = {
          inherit (pin) identity name location;
          kind = "remoteSourceControl";
        };
        state = {
          name = "sourceControlCheckout";
          checkoutState = { inherit (pin) revision version; };
        };
        inherit (pin) subpath;
      }) pins;
    };
  };

  packageResolved = {
    version = 3;
    inherit (pinData) originHash;
    pins = lib.sortOn (p: p.identity) (
      lib.mapAttrsToList (_: pin: {
        inherit (pin) identity location;
        kind = "remoteSourceControl";
        state = { inherit (pin) revision version; };
      }) pins
    );
  };
in
{
  inherit checkouts;

  # Shell commands that put the dependencies in place.
  configure = ''
    mkdir -p '${scratchPath}/checkouts'
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: pin: "ln -s ${checkouts.${name}} '${scratchPath}/checkouts/${pin.subpath}'"
      ) pins
    )}
    install -m 0600 ${builtins.toFile "workspace-state.json" (builtins.toJSON workspaceState)} \
      '${scratchPath}/workspace-state.json'
    install -m 0600 ${builtins.toFile "Package.resolved" (builtins.toJSON packageResolved)} \
      '${packageRoot}/Package.resolved'
  '';
}
