{ self, config, system, lib, pkgs, ... }:

{
  services.printing = {
    enable = true;
    drivers = [
      # Generic
      pkgs.cups-pdf-to-pdf
      pkgs.gutenprint
      pkgs.cups-filters
      # Dymo
      pkgs.cups-dymo
      # Zijang ZJ-58
      pkgs.cups-zj-58
      # Kyocera
      pkgs.cups-kyocera
      pkgs.cups-kyodialog
      pkgs.cups-kyocera-ecosys-m552x-p502x
      pkgs.cups-kyocera-ecosys-m2x35-40-p2x35-40dnw
      pkgs.cups-toshiba-estudio
      pkgs.cups-brother-hl1110
      pkgs.cups-brother-hl2260d
      pkgs.cups-brother-hl1210w
      pkgs.cups-brother-hl3140cw
      pkgs.cups-brother-hll2375dw
      pkgs.cups-brother-hll2350dw
      pkgs.cups-brother-hll2340dw
      pkgs.cups-brother-mfcl2750dw
      pkgs.cups-brother-hll3230cdw
      pkgs.brgenml1cupswrapper
      pkgs.mfc465cncupswrapper
      pkgs.mfcj880dwcupswrapper
      pkgs.mfcj470dw-cupswrapper
      pkgs.mfcl3770cdwcupswrapper
      pkgs.mfcl2740dwcupswrapper
      pkgs.mfcl2720dwcupswrapper
      pkgs.mfcl2700dncupswrapper
      pkgs.mfcj6510dw-cupswrapper
      pkgs.mfc9140cdncupswrapper
      pkgs.mfc5890cncupswrapper
      pkgs.mfcl8690cdwcupswrapper
      pkgs.dcp375cw-cupswrapper
      pkgs.dcp9020cdw-cupswrapper
      pkgs.brlaser
      pkgs.gutenprintBin
      pkgs.hll2390dw-cups
      # Ricoh
      pkgs.cups-drv-rastertosag-gdi
      # Canon
      pkgs.cups-bjnp
      pkgs.carps-cups
      pkgs.canon-cups-ufr2
      # Epson
      pkgs.epson-workforce-635-nx625-series
      pkgs.epson-escpr
      # Samsung
      pkgs.splix
      # Lexmark
      pkgs.lexmark-aex
    ]
    ++ (builtins.map (ppd: (pkgs.writeTextDir "/share/cups/model/${ppd}" (builtins.readFile "${self}/config/cups_drivers/ppd/${ppd}"))) (builtins.attrNames (builtins.readDir "${self}/config/cups_drivers/ppd")))
    ++ (builtins.map (filter: (pkgs.writeTextFile {
      name = filter;
      executable = true;
      destination = "/lib/cups/filter/${filter}";
      text = ''
        #!/bin/sh
        "${self}/config/cups_drivers/filter/${system}/${filter}" "$@"
      '';
    })) (builtins.attrNames (builtins.readDir "${self}/config/cups_drivers/filter/${system}")));
  };
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [];
  };
}
