{ config, lib, pkgs, ... }:

{
  users.users.guest = {
    isNormalUser = true;
    description = "guest";
  };
  home-manager.users.guest = {};
}
