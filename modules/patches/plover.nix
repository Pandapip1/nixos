{
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    (_: prev: {
      plover_5 = prev.plover.overrideAttrs (prevAttrs: {
        src = prev.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "plover";
          rev = "722d8d663d5ca1df8ac1abc38229302f0adba1d5"; # ime-probing
          hash = "sha256-p2E8lAMWvxt58LQ9ELyzhoJv12DmYeTCovGvMeL49Ro=";
        };
      });
    })
  ];
}
