{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.users.priyanka = {
    enable = lib.mkDefault false;
    isNormalUser = true;
    description = "priyanka";
    extraGroups = [
      "audio"
      "plugdev"
    ];
    packages = with pkgs; [ ];
  };
}
