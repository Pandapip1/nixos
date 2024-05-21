{ pkgs, ... }:
let
  steam = pkgs.steam.override {
  };
in
{
  environment.systemPackages = with pkgs; [
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
    gamescopeSession.enable = false; # Manually invoke gamescope
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
