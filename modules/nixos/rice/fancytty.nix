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
  kmsconStart = pkgs.writeShellScriptBin "kmscon-start" ''
    sleep 1
    exec ${lib.getExe pkgs.kmscon} --no-switchvt --login -- ${lib.getExe execLoginShell}
  '';
  kmsconSession =
    (pkgs.makeDesktopItem {
      destination = "/share/wayland-sessions";
      desktopName = "kmscon";
      name = "kmscon-session";
      comment = "KMS/DRM text console session";
      exec = lib.getExe kmsconStart;
      type = "Application";
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
