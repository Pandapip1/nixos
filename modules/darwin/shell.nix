{
  config,
  lib,
  pkgs,
  ...
}:

let
  user = config.system.primaryUser;
  # A stable path that survives generation switches, unlike a store path.
  loginShell = "/run/current-system/sw/bin/bash";
in
{
  programs.bash.enable = true;

  # Interactive bash (with readline), listed in /etc/shells so macOS accepts it.
  environment.systemPackages = [ pkgs.bashInteractive ];
  environment.shells = [ loginShell ];

  # nix-darwin only applies users.users.<name>.shell to users in
  # users.knownUsers, and the admin user must not be put there (nix-darwin
  # would then create/delete it). Set the login shell directly instead.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    if [ "$(dscl . -read /Users/${user} UserShell | awk '{print $2}')" != "${loginShell}" ]; then
      echo "setting login shell for ${user} to ${loginShell}..." >&2
      dscl . -create /Users/${user} UserShell ${loginShell}
    fi
  '';
}
