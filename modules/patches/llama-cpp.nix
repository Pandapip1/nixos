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
          rev = "657e6659edabee3fa94eeae564ef6c20b1368407"; # vulkan-global-prio
          hash = "sha256-Dmkr98t1Xf+Vn/aKWS/vwLACWld9Wkx+izuS79pzVDg=";
        };
      });
    })
  ];
}
