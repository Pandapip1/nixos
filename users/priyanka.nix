{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.users.priyanka = {
    isNormalUser = true;
    description = "priyanka";
    extraGroups = [
      "audio"
    ];
    packages = with pkgs; [ ];
  };
}
