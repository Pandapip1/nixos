{
  config,
  pkgs,
  ...
}:
let
  # pam_ropc =
  #   with pkgs;
  #   rustPlatform.buildRustPackage (finalAttrs: {
  #     pname = "pam-ropc";
  #     version = "nightly";

  #     src = self.outPath;

  #     cargoLock = {
  #       lockFile = finalAttrs.src + "/Cargo.lock";
  #     };

  #     buildInputs = [
  #       pam
  #     ];

  #     postInstall = ''
  #       mkdir -p $out/lib/security
  #       ln -s $out/lib/libpam_ropc.so $out/lib/security/pam_ropc.so
  #     '';
  #   });
in
{

}
