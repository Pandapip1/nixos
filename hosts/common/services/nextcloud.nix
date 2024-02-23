{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nextcloud-client
  ];
}
