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

    # Disable core dumps for SUID programs (I don't know exactly why this is good but I can't see it being actively harmful)
    fs.suid_dumpable = 0;

    # Hide kernel pointers to make attacks harder
    kernel.kptr_restrict = 2;

    # Disable SysRq key
    kernel.sysrq = 0;

    # Disable unprivileged bpf
    kernel.unprivileged_bpf_disabled = 1;

    # Enable hardening for the JIT compiler
    net.core.bpf_jit_harden = 2;

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
      };
    };

    # Log invalid packets
    net.ipv4.conf.all.log_martians = 1;
    net.ipv4.conf.default.log_martians = 1;

    # Enable reverse path filtering
    net.ipv4.conf.all.rp_filter = 1;
  };
}
