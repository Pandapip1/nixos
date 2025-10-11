{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    killall
    btop
    dig
  ];
}