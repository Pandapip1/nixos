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
      # Disabled, broken on aarch64 apparently
      # mandoc.enable = lib.mkDefault true; # BSD-compatible
      cache.enable = lib.mkDefault true;
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
