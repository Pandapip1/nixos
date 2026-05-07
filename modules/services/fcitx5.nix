{
  pkgs,
  ...
}:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      ignoreUserConfig = true;
      waylandFrontend = false; # COSMIC does not warn

      addons = with pkgs; [
        fcitx5-gtk
        qt6Packages.fcitx5-configtool
        libsForQt5.fcitx5-qt
        qt6Packages.fcitx5-qt
      ];
    };
  };
}