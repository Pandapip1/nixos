{
  pkgs,
  ...
}:

{
  services.displayManager.sessionPackages = [
    (pkgs.makeDesktopItem {
      destination = "/share/wayland-sessions";
      name = "Stardust XR";
      comment = "TODO";
      exec = lib.getExe pkgs.stardust-xr-server;
      type = "Application";
      desktopName = "Stardust XR";
    })
    (pkgs.makeDesktopItem {
      destination = "/share/wayland-sessions";
      name = "kmscon";
      comment = "TODO";
      exec = lib.getExe pkgs.kmscon;
      type = "Application";
      desktopName = "kmscon";
    })
  ];
}
