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
      geoclue2-with-asan = prev.enableDebugging (
        prev.geoclue2.overrideAttrs (
          _: previousAttrs: {
            mesonFlags = [
              (lib.mesonOption "b_sanitize" "address")
              (lib.mesonBool "b_lundef" false)
              (lib.mesonBool "b_pie" true)
              (lib.mesonBool "gtk-doc" false)
            ] ++ previousAttrs.mesonFlags;

            postInstall = ''
              mkdir -p $devdoc
            '';
          }
        )
      );
    })
  ];
  services.geoclue2.package = pkgs.geoclue2-with-asan;
}
