{
  config,
  pkgs,
  ...
}:

{
  programs.bash.enable = true;
  users.users.${config.system.primaryUser}.shell = pkgs.bash;
}
