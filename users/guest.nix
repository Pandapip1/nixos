{ config, lib, pkgs, ... }:

{
  users.users.gavin = {
    isNormalUser = true;
    description = "guest";
  };
  home-manager.users.guest = {};
}
