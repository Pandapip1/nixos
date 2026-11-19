{ lib, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      nginxStable = prev.nginxStable.overrideAttrs (old: rec {
        version = "1.30.7";
        nginxVersion = version;

        src = prev.fetchurl {
          url = "https://nginx.org/download/nginx-${version}.tar.gz";
          hash = "sha256-JWW1yDcFDpWPcPsPc8SOK8pFQq00n9NW9G+wxyYQvG4=";
        };
      });

      nginxMainline = prev.nginxMainline.overrideAttrs (old: rec {
        version = "1.31.9";
        nginxVersion = version;

        src = prev.fetchurl {
          url = "https://nginx.org/download/nginx-${version}.tar.gz";
          hash = "sha256-oRxe7uLiV/RHjw5kn4SwBAeH0nfS0+UjOVKqa23LgK0=";
        };
      });

      nginx = final.nginxStable;
    })
  ];
}
