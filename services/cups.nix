{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-pdf-to-pdf
      gutenprint
      hplipWithPlugin
      cups-idprt-tspl
    ];
  };
}
