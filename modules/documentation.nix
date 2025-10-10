{
  lib,
  ...
}:

{
  documentation = {
    enable = lib.mkDefault true;
    man = {
      enable = lib.mkDefault true;
      man-db.enable = lib.mkDefault false;
      mandoc.enable = lib.mkDefault true; # BSD-compatible
      generateCaches = lib.mkDefault true;
    };
    doc.enable = lib.mkDefault true;
    dev.enable = lib.mkDefault true;
    info.enable = lib.mkDefault true;
    nixos = {
      enable = lib.mkDefault true;
      #includeAllModules = lib.mkDefault true;
    };
  };
}
