# nixpkgs' glib-2.0.pc and gio-2.0.pc carry `Requires.private: sysprof-capture-4`,
# but no nixpkgs package installs a sysprof-capture-4.pc (sysprof ships
# sysprof-6.pc, and the capture library itself is built into glib). The real
# pkg-config binary only resolves private requires for --static, so GTK builds
# normally never notice.
#
# SwiftPM does not shell out to pkg-config: it parses .pc files itself and always
# walks the private chain. One unresolvable entry makes it drop *every* flag for
# the module, so `import CGTK` fails with "'gtk/gtk.h' file not found" and only a
# "couldn't find pc file for sysprof-capture-4" warning to explain it.
#
# This stub satisfies the chain. It is correct for the dynamic link Hummingbird
# does: the capture symbols already live inside libglib-2.0.so, so there is
# nothing extra to add to cflags or libs.
{ writeTextDir }:
writeTextDir "lib/pkgconfig/sysprof-capture-4.pc" ''
  Name: sysprof-capture-4
  Description: Stub satisfying glib's Requires.private (see nix/sysprof-capture-stub.nix)
  Version: 3.38.0
  Cflags:
  Libs:
''
