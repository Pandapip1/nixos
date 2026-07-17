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
          rev = "839100918c2e10dbf2057a092b00153bd9d9dd24"; # sbs-pnp
          hash = "sha256-C/okxu/Dwia4aynJ3iWYLmxLsRIjGCC0/K+t6QfjNns=";
        };

        patches = [ ];
      });
    })
  ];
  services.monado.package = pkgs.monado-sbs-pnp;
  security.wrappers."monado-service".capabilities = lib.mkForce "cap_sys_nice,cap_dac_override+eip";
  services.monado.highPriority = lib.mkForce true;
}
