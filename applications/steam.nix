{ pkgs, ... }:
let
  steam = pkgs.steam.override {
    extraPkgs = pkgs: with pkgs; [
      gamescope
    ];
  };
  lutris = pkgs.lutris.override {
    extraLibraries =  pkgs: [
      # List library dependencies here
    ];
    extraPkgs = pkgs: [
      # List package dependencies here
    ];
  };
in
{
  environment.systemPackages = with pkgs; [
    lutris
    gamescope
    gamemode
    mangohud
    vkbasalt
    vkbasalt-cli
  ] ++ [ steam steam.run ];
  programs.steam = {
    enable = true;
    package = steam;
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for local network game transfers
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    gamescopeSession.enable = true; # Automatically invoke gamescope
    protontricks.enable = true;
    extest.enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
    args = [
      "-f"
    ];
  };
}
