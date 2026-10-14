{
  lib,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    cutecosmic
  ];
  qt = {
    enable = true;
    # platformTheme = "cosmic";
  };
  environment.variables = {
    QT_QPA_PLATFORMTHEME = lib.mkForce "cosmic";
  };
}
