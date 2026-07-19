{
  lib,
  pkgs,
  ...
}:

let
  execLoginShell = pkgs.stdenv.mkDerivation {
    name = "exec-login-shell";

    src = ./exec-login-shell.c;

    dontUnpack = true;
    dontConfigure = true;

    buildPhase = ''
      $CC \
        -Wall -Wextra -O2 \
        "$src" \
        -o exec-login-shell
    '';

    installPhase = ''
      install -Dm755 exec-login-shell \
        $out/bin/exec-login-shell
    '';

    meta.mainProgram = "exec-login-shell";
  };
  kmsconSession =
    (pkgs.makeDesktopItem {
      destination = "/share/wayland-sessions";
      name = "kmscon-session";
      comment = "KMS/DRM text console session";
      exec = ''${lib.getExe pkgs.kmscon} --vt="\\$XDG_VTNR" --no-switchvt -- ${lib.getExe execLoginShell}'';
      type = "Application";
      desktopName = "kmscon-session";
    }).overrideAttrs
      (oldAttrs: {
        passthru = (oldAttrs.passthru or { }) // {
          providedSessions = [ "kmscon-session" ];
        };
      });
in
{
  services.kmscon = {
    enable = true;
    config.hwaccel = true;
  };
  services.displayManager.sessionPackages = [
    kmsconSession
  ];
}
