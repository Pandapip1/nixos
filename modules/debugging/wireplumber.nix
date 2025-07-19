{
  pkgs,
  ...
}:

let
  inherit (pkgs) lib;
in
{
  nixpkgs.overlays = [
    (_: prev: {
      wireplumber-debug = prev.enableDebugging prev.wireplumber;
    })
  ];
  services.pipewire.wireplumber.package = "wireplumber-debug";
}
