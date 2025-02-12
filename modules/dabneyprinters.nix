{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.dabney.printers;

in {
  options = {
    dabney.printers = {
      enable = mkEnableOption "Dabney's printers" // {
        default = true;
      };
    };
  };

  config = mkIf cfg.enable {
    hardware.printers = {
      ensurePrinters = [
        {
          name = "Apathy";
          location = "Lounge";
          deviceUri = "http://apathy.dabney.caltech.edu:631/printers/Apathy";
          model = "drv:///sample.drv/generic.ppd";
          ppdOptions = {
            PageSize = "na_letter_8.5x11in";
          };
        }
      ];
    };
  };
}
