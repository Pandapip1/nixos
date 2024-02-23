{ config, lib, pkgs, ... }:

{
  users.users.gavin = {
    isNormalUser = true;
    description = "gavin";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ ];
  };
}
