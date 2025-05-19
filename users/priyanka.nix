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
      "plugdev"
    ];
    packages = with pkgs; [ ];
  };
}
