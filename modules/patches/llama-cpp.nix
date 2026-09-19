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
          rev = "1e04de3cef4a91d1ecea540f70cbf95889ffc82d"; # vulkan-global-prio
          hash = "sha256-KcZxdiCXFnakYidfykCitznRJSdLYR+awvaxLiMAqAc=";
        };
      });
    })
  ];
}
