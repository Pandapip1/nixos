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
      pipewire-debug-fixed = prev.enableDebugging (prev.pipewire.overrideAttrs (old: {
        patches = (old.patches or []) ++ [
          ./pipewire-bluez5-telephony-null-check.patch
        ];
      }));
    })
  ];
  services.pipewire.wireplumber.package = pkgs.wireplumber-debug;
  services.pipewire.package = pkgs.pipewire-debug-fixed;
}
