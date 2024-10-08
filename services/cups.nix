{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      # Generic
      cups-pdf-to-pdf
      gutenprint
      cups-filters
      lprint
      # HP
      hplipWithPlugin
      # Dymo
      cups-dymo
      # Zijang ZJ-58
      cups-zj-58
      # Kyocera
      cups-kyocera
      cups-kyodialog
      cups-kyocera-ecosys-m552x-p502x
      cups-kyocera-ecosys-m2x35-40-p2x35-40dnw
      cups-toshiba-estudio
      cups-brother-hl1110
      cups-brother-hl2260d
      cups-brother-hl1210w
      cups-brother-hl3140cw
      cups-brother-hll2375dw
      cups-brother-hll2350dw
      cups-brother-hll2340dw
      cups-brother-mfcl2750dw
      cups-brother-hll3230cdw
      brgenml1cupswrapper
      mfc465cncupswrapper
      mfcj880dwcupswrapper
      mfcj470dw-cupswrapper
      mfcl3770cdwcupswrapper
      mfcl2740dwcupswrapper
      mfcl2720dwcupswrapper
      mfcl2700dncupswrapper
      mfcj6510dw-cupswrapper
      mfc9140cdncupswrapper
      mfc5890cncupswrapper
      mfcl8690cdwcupswrapper
      dcp375cw-cupswrapper
      dcp9020cdw-cupswrapper
      brlaser
      gutenprintBin
      # Ricoh
      cups-drv-rastertosag-gdi
      # Canon
      cups-bjnp
      carps-cups
      canon-cups-ufr2
      # Epson
      epson-escpr
      # Samsung
      splix
      # Lexmark
      lexmark-aex
      # Custom drivers
      cups-idprt-tspl
      cups-idprt-barcode
      cups-idprt-mt888
      cups-idprt-mt890
      cups-idprt-sp900
    ];
  };
  environment.systemPackages = with pkgs; [
    lprint
  ];
}
