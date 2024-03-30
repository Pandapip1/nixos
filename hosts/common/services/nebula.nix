{ hostname, config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nebula
  ];
  services.nebula.networks.mesh = {
    enable = false;
    isLighthouse = true;
    cert = builtins.readFile "../../../config/${hostname}.crt";
    key = "/etc/secrets/${hostname}.key";
    ca = builtins.readFile "../../../config/ca.crt";
  };
}
