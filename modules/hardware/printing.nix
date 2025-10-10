{
  lib,
  pkgs,
  ...
}:

{
  services.printing = {
    enable = lib.mkDefault true;
    startWhenNeeded = lib.mkDefault true;
    drivers = with pkgs; [
      cups-pdf-to-pdf
      gutenprint
      cups-idprt-tspl
    ];
  };
}
