{ config, lib, pkgs, nix-software-center, nixos-conf-editor, ... }:

{
  environment.systemPackages = with pkgs; [
    home-assistant
    home-assistant-cli
  ];
  networking.firewall.allowedTCPPorts = [ 8123 ];
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "esphome"
      "met"
      "radio_browser"
      "google_translate"
      "zha"
    ];
    config = {
      default_config = {};
    };
  };
  nixpkgs.config.permittedInsecurePackages = [ # TODO: Remove this at some point?
    "openssl-1.1.1w"
  ];
}
