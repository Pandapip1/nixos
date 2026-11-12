{
  tor,
  apple-sdk,
  runCommand,
}:

# Tor with transparent-proxy support (TransPort) on macOS. Tor needs pf's
# NAT-lookup ioctl to find where a redirected connection was going, and that
# lives in <net/pfvar.h>, which Apple leaves out of the public SDK; without it
# Tor's configure turns TransPort off ("TransPort is disabled in this build").
# The header is in XNU's published source, so build against that copy.
let
  xnu = apple-sdk.sourceRelease "xnu";
  pfHeaders = runCommand "xnu-pf-headers" { } ''
    install -Dm444 ${xnu}/bsd/net/pfvar.h $out/include/net/pfvar.h
    install -Dm444 ${xnu}/bsd/net/radix.h $out/include/net/radix.h
    install -Dm444 ${xnu}/libkern/libkern/tree.h $out/include/libkern/tree.h
  '';
in
tor.overrideAttrs (old: {
  pname = "tor-pf";
  # Apple's pf names these fields differently from the BSD pf Tor targets:
  # addresses are v4addr/v6addr and ports sit in an xport union. Rewrite only
  # the uses of the NAT-lookup structure (always called pnl in Tor).
  postPatch = (old.postPatch or "") + ''
    sed -E -i \
      -e 's/pnl\.(saddr|daddr|rdaddr)\.v4\b/pnl.\1.v4addr/g' \
      -e 's/pnl\.(saddr|daddr|rdaddr)\.v6\b/pnl.\1.v6addr/g' \
      -e 's/pnl\.(s|d|rd)port\b/pnl.\1xport.port/g' \
      src/core/or/connection_edge.c
    # The options test has no macOS case for a TransPort-enabled build; macOS
    # uses the same "default" proxy type as NetBSD.
    substituteInPlace src/test/test_options.c \
      --replace-fail '#elif defined(__NetBSD__)' '#elif defined(__NetBSD__) || defined(__APPLE__)'
  '';
  # PRIVATE exposes the userland parts of pfvar.h (the ioctl structures).
  env = (old.env or { }) // {
    NIX_CFLAGS_COMPILE = toString [
      (old.env.NIX_CFLAGS_COMPILE or "")
      "-DPRIVATE"
      "-I${pfHeaders}/include"
    ];
  };
})
