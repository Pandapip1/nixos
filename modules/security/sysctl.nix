{
  lib,
  ...
}:

let
  flattenAttrs =
    let
      flattenAttrsHelper =
        prefix: attrs:
        lib.foldl' (
          acc: key:
          let
            value = attrs.${key};
            fullKey = prefix ++ [ key ];
          in
          if lib.isAttrs value && !(lib.isFunction value) then
            acc // (flattenAttrsHelper fullKey value)
          else
            acc // { "${lib.concatStringsSep "." fullKey}" = value; }
        ) { } (lib.attrNames attrs);
    in
    attrset: flattenAttrsHelper [ ] attrset;
in
{
  boot.kernel.sysctl = flattenAttrs {
    dev.tty.ldisc_autoload = 0;
    fs.protected_fifos = 2;
    fs.protected_regular = 2;
  };
}
