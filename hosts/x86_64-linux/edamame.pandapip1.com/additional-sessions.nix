{
  pkgs,
  ...
}:

{
  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      stardustxr = {
        prettyName = "Stardust XR";
        comment = "TODO stardust-xr";
        binPath = lib.getExe pkgs.stardust-xr-server;
      };
      kmscon = {
        prettyName = "kmscon";
        comment = "TODO kmscon";
        binPath = lib.getExe pkgs.kmscon;
      };
    };
  };
}
