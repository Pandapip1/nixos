{
  pkgs,
  ...
}:

{
  users.defaultUserShell = pkgs.bash;
  programs.bash.enable = true;
}
