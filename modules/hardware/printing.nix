{
  lib,
  pkgs,
  ...
}:

{
  services.printing = {
    enable = lib.mkDefault true;
    startWhenNeeded = lib.mkDefault true;
    drivers =
      with pkgs;
      [
        cups-pdf-to-pdf
        gutenprint
      ]
      ++ (lib.optional (stdenv.hostPlatform.system == "x86_64-linux") cups-idprt-tspl);
  };
}
