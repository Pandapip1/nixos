{
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.overlays = [
    (_: prev: {
      monado-sbs-pnp = prev.monado.overrideAttrs (prevAttrs: {
        pname = "${prevAttrs.pname}-sbs-pnp";
        version = "0-unstable-2026-07-15";
        src = prev.fetchFromGitLab {
          domain = "gitlab.freedesktop.org";
          owner = "pandapip1";
          repo = "monado";
          rev = "1d84bafaa0089bf4ea73dd56353a9e4aa8c249d5"; # sbs-pnp
          hash = "sha256-IQETmVInLNY2GtPYWm9PvGGuhP5KaDT5nW5r//CJBv4=";
        };

        patches = [ ];
      });
    })
  ];
  services.monado.package = pkgs.monado-sbs-pnp;
  security.wrappers."monado-service".capabilities = lib.mkForce "cap_sys_nice,cap_dac_override+eip";
  services.monado.highPriority = lib.mkForce true;
}
