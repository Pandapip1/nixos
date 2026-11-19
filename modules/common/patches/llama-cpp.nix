{
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    (_: prev: {
      llama-cpp = prev.llama-cpp.overrideAttrs (prevAttrs: {
        src = prev.fetchFromGitHub {
          owner = "pandapip1";
          repo = "llama.cpp";
          rev = "1a8b885b20495040d14a7386b7182e93a3a52c22"; # vulkan-global-prio
          hash = "sha256-XLyJAPsI5mZ0yufO0ylYfJZnms+RmiJCuqKAh40JVAk=";
        };
        # The fork's tools/ui/package-lock.json differs from upstream's, so
        # nixpkgs' npmDepsHash (computed for upstream's lockfile) no longer
        # matches.
        npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
      });
    })
  ];
}
