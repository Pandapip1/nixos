{
  pkgs,
  ...
}:

let
  inherit (prev) lib;
in
{
  nixpkgs.overlays = [
    (_: prev: {
      geoclue2-with-asan = prev.enableDebugging (
        prev.geoclue2.overrideAttrs (
          _: previousAttrs: {
            mesonFlags = [
              (lib.mesonOption "b_sanitize" "address")
              (lib.mesonBool "b_lundef" false)
              (lib.mesonBool "b_pie" true)
            ] ++ previousAttrs.mesonFlags;
          }
        )
      );
    })
  ];
  services.geoclue2.package = "geoclue2-with-asan";
}
