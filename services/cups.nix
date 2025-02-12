{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    startWhenNeeded = false;
    drivers = with pkgs; [
      cups-pdf-to-pdf
      gutenprint
      hplipWithPlugin
      cups-idprt-tspl
    ];
  };
}
