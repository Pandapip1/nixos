{ system, vector, ... }:

{
  environment.systemPackages = [
    vector.packages.${system}.default
  ];
}
