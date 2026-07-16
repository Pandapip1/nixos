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
          rev = "9bf968ee543a352218ca8b87d90c288ca86da5a8"; # sbs-pnp
          hash = "sha256-2wwwF7TTsewCa5Bdtu4XvbEjuuj2Q8tiG63oDvF/a/c=";
        };

        patches = [ ];
      });
    })
  ];
  services.monado.package = pkgs.monado-sbs-pnp;
  security.wrappers."monado-service".capabilities = lib.mkForce "cap_sys_nice,cap_dac_override+eip";
  services.monado.highPriority = lib.mkForce true;
}
