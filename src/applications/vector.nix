{ config, lib, pkgs, vector, ... }:

{
  environment.systemPackages = with pkgs; [
    vector.packages.${system}.default
  ];
}
