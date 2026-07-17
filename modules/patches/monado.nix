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
          rev = "d53f1f50e21c4a7deee663e44612473a9918c9b3"; # sbs-pnp
          hash = "sha256-0nTi/X7I0x+6zEGqJ/Ydd2sjidnQupJlSzGFnH2hlQM=";
        };

        patches = [ ];
      });
    })
  ];
  services.monado.package = pkgs.monado-sbs-pnp;
  security.wrappers."monado-service".capabilities = lib.mkForce "cap_sys_nice,cap_dac_override+eip";
  services.monado.highPriority = lib.mkForce true;
}
