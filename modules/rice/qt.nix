{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    cutecosmic
  ];
  qt = {
    enable = true;
    platformTheme = "cosmic";
  };
}
