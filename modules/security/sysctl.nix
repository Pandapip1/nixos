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

    # Enable some filesystem protections for potentially vulnerable programs interacting with world-writable files
    fs = {
      protected_fifos = 2;
      protected_regular = 2;
    };

    # Disable ICMP redirects
    net = {
      ipv4.conf = {
        all = {
          accept_redirects = 0;
          send_redirects = 0;
        };
        default.accept_redirects = 0;
      };
      ipv6.conf = {
        all.accept_redirects = 0;
        default.accept_redirects = 0;
      }
    };
  };
}
