
{
  nixpkgs.overlays = [
    (_: prev: {
      pam_ropc = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "pam_ropc";
        version = "0-unstable-TODO";

        src = prev.fetchFromCodeberg {
          owner = "pandapip1";
          repo = "pam-ropc";
          rev = "2155afe3815f3bb13ff83bdf6736bd9749fffb92";
          hash = "sha256-Y3rA/ytpWzkL/xVQZ8uckMJMwbRiBw98fPdv8Y/mO+0=";
        };

        cargoLock = {
          lockFile = finalAttrs.src + "/Cargo.lock";
          allowBuiltinFetchGit = true;
        };
            
        buildInputs = with prev; [
          libsodium
          pam
        ];

        postInstall = ''
          mkdir -p $out/lib/security
          ln -s $out/lib/libpam_ropc.so $out/lib/security/pam_ropc.so
        '';
      });
    })
  ];
}
