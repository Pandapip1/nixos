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
      });
    })
  ];
}
