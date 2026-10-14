{
  pkgs,
  ...
}:

{
  environment.enableAllTerminfo = true;

  nixpkgs.overlays = [
    (_: super: {
      termite = {
        terminfo = super.emptyDirectory;
      };
    })
  ];
}
