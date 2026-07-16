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
          rev = "ee2672f8e28ec8c9c934b763e35f7ea446b3cd44"; # sbs-pnp
          hash = "sha256-fOSWaaQz5/StS9kjMREk9d3v3D/oYZ1f5mtU/6bMnTc=";
        };

        patches = [ ];
      });
    })
  ];
  services.monado.package = pkgs.monado-sbs-pnp;
  security.wrappers."monado-service".capabilities = lib.mkForce "cap_sys_nice,cap_dac_override+eip";
  services.monado.highPriority = lib.mkForce true;
}
