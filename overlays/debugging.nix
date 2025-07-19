_: prev:
let
  inherit (prev) lib;
in
{
  geoclue2 = prev.enableDebugging (prev.geoclue2.overrideAttrs (
    _: previousAttrs: {
      mesonFlags = [
        (lib.mesonOption "b_sanitize" "address")
        (lib.mesonBool "b_lundef" false)
        (lib.mesonBool "b_pie" true)
      ] ++ previousAttrs.mesonFlags;
    }
  ));
  wireplumber = prev.enableDebugging prev.wireplumber;
}
