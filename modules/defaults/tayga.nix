{
  pkgs,
  ...
}:

{
  services.tayga = {
    enable = true;
    # TODO: Upstream
    package = pkgs.tayga.overrideAttrs (finalAttrs: _: {
      version = "0.9.5";

      src = pkgs.fetchFromGitHub {
        owner = "apalrd";
        repo = "tayga";
        tag = finalAttrs.version;
        hash = "sha256-xOm4fetFq2UGuhOojrT8WOcX78c6MLTMVbDv+O62x2E=";
      };
    });
    ipv4 = {
      address = "172.31.255.0";
      router = {
        address = "172.31.255.1";
      };
      pool = {
        address = "172.31.255.1";
        prefixLength = 24;
      };
    };
    ipv6 = {
      address = "2001:db8::1";
      router = {
        address = "64:ff9b::1";
      };
      pool = {
        address = "64:ff9b::";
        prefixLength = 96;
      };
    };
  };
}
