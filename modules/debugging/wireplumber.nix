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
      pipewire-debug = prev.enableDebugging (prev.pipewire);
    })
  ];
  services.pipewire.wireplumber.package = pkgs.wireplumber-debug;
  services.pipewire.package = pkgs.pipewire-debug;
}
