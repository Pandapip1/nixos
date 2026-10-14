{
  pkgs,
  ...
}:

{
  # TODO: Fix on aarch64
  services.comlsldd.enable = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
}
