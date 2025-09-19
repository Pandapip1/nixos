{
  pkgs,
}:

{
  nixowos.enable = true;
  environment.systemPackages = with pkgs; [
    fastfetch
  ];
}
