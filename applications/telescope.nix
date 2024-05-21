{ system, telescope, ... }:

{
  environment.systemPackages = [
    telescope.packages.${system}.default
    telescope.packages.${system}.flatscreen
  ];
}
