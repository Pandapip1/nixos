{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    steam
    steam-run
    gamescope
    gamemode
    mangohud
    vkbasalt
    vkbasalt-cli
  ];
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    gamescopeSession.enable = false; # Manually invoke gamescope
  };
  programs.gamescope = {
    enable = true;
  };
}
