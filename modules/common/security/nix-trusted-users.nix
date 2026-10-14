{ config, ... }:

{
  nix.settings.trusted-users = [ (if config.moduleClass == "nixos" then "@wheel" else "@admin") ];
}
