{ system, pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.android-tools
  ];
  programs.envision.enable = true;
}
