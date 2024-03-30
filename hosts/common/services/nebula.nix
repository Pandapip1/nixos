{ hostname, config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nebula
  ];
  services.nebula.networks.nebula0 = {
    enable = true;
    isLighthouse = false;
    cert = builtins.readFile "../../../config/nebula/${hostname}.crt";
    key = "/etc/secrets/nebula/${hostname}.key";
    ca = builtins.readFile "../../../config/nebula/ca.crt";
  };
}
