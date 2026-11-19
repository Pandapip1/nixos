{ lib, stdenvNoCC, patchelf, webkitgtk_6_0, icu, harfbuzzFull }:

# Swift Foundation ships an Apple ICU build whose ELF sonames overlap upstream
# ICU. WebKitGTK needs upstream ICU, so loading both ordinary closures in one
# process can bind either consumer to the other's incompatible implementation.
# Keep upstream ICU's versioned symbols intact but route WebKitGTK to private
# sonames. This lets the dynamic loader retain both implementations.
stdenvNoCC.mkDerivation {
  pname = "webkitgtk-swift-compatible";
  inherit (webkitgtk_6_0) version;
  dontUnpack = true;
  nativeBuildInputs = [ patchelf ];

  installPhase = ''
    mkdir -p "$out/lib/pkgconfig" "$out/include"

    cp -L ${lib.getLib webkitgtk_6_0}/lib/libwebkitgtk-6.0.so.4 "$out/lib/"
    cp -L ${lib.getLib webkitgtk_6_0}/lib/libjavascriptcoregtk-6.0.so.1 "$out/lib/"
    ln -s libwebkitgtk-6.0.so.4 "$out/lib/libwebkitgtk-6.0.so"
    ln -s libjavascriptcoregtk-6.0.so.1 "$out/lib/libjavascriptcoregtk-6.0.so"
    cp -L ${lib.getLib icu}/lib/libicudata.so.78 "$out/lib/libicudata-webkit.so.78"
    cp -L ${lib.getLib icu}/lib/libicuuc.so.78 "$out/lib/libicuuc-webkit.so.78"
    cp -L ${lib.getLib icu}/lib/libicui18n.so.78 "$out/lib/libicui18n-webkit.so.78"
    cp -L ${lib.getLib harfbuzzFull}/lib/libharfbuzz-icu.so.0 "$out/lib/libharfbuzz-icu-webkit.so.0"
    chmod u+w "$out"/lib/*.so.*

    ln -s ${lib.getDev webkitgtk_6_0}/include/webkitgtk-6.0 "$out/include/webkitgtk-6.0"
    substitute ${lib.getDev webkitgtk_6_0}/lib/pkgconfig/webkitgtk-6.0.pc "$out/lib/pkgconfig/webkitgtk-6.0.pc" \
      --replace-fail 'prefix=${lib.getLib webkitgtk_6_0}' "prefix=$out" \
      --replace-fail 'libdir=${lib.getLib webkitgtk_6_0}/lib' "libdir=$out/lib" \
      --replace-fail 'includedir=${lib.getDev webkitgtk_6_0}/include' "includedir=$out/include"
    substitute ${lib.getDev webkitgtk_6_0}/lib/pkgconfig/javascriptcoregtk-6.0.pc "$out/lib/pkgconfig/javascriptcoregtk-6.0.pc" \
      --replace-fail 'prefix=${lib.getLib webkitgtk_6_0}' "prefix=$out" \
      --replace-fail 'libdir=${lib.getLib webkitgtk_6_0}/lib' "libdir=$out/lib" \
      --replace-fail 'includedir=${lib.getDev webkitgtk_6_0}/include' "includedir=$out/include"

    patchelf --set-soname libicudata-webkit.so.78 "$out/lib/libicudata-webkit.so.78"
    patchelf --set-soname libicuuc-webkit.so.78 "$out/lib/libicuuc-webkit.so.78"
    patchelf --replace-needed libicudata.so.78 libicudata-webkit.so.78 "$out/lib/libicuuc-webkit.so.78"
    patchelf --set-soname libicui18n-webkit.so.78 "$out/lib/libicui18n-webkit.so.78"
    patchelf --replace-needed libicuuc.so.78 libicuuc-webkit.so.78 "$out/lib/libicui18n-webkit.so.78"
    patchelf --replace-needed libicudata.so.78 libicudata-webkit.so.78 "$out/lib/libicui18n-webkit.so.78"

    patchelf --set-soname libharfbuzz-icu-webkit.so.0 "$out/lib/libharfbuzz-icu-webkit.so.0"
    patchelf --replace-needed libicuuc.so.78 libicuuc-webkit.so.78 "$out/lib/libharfbuzz-icu-webkit.so.0"

    for library in libwebkitgtk-6.0.so.4 libjavascriptcoregtk-6.0.so.1; do
      patchelf --replace-needed libicudata.so.78 libicudata-webkit.so.78 "$out/lib/$library"
      patchelf --replace-needed libicui18n.so.78 libicui18n-webkit.so.78 "$out/lib/$library"
      patchelf --replace-needed libicuuc.so.78 libicuuc-webkit.so.78 "$out/lib/$library"
      patchelf --set-rpath '$ORIGIN:'"$(patchelf --print-rpath "$out/lib/$library")" "$out/lib/$library"
    done
    patchelf --replace-needed libharfbuzz-icu.so.0 libharfbuzz-icu-webkit.so.0 "$out/lib/libwebkitgtk-6.0.so.4"
  '';

  meta = webkitgtk_6_0.meta;
}
