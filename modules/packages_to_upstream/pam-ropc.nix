
{
  nixpkgs.overlays = [
    (_: prev: {
      pam_ropc = prev.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "pam_ropc";
        version = "0-unstable-TODO";

        src = prev.fetchFromCodeberg {
          owner = "pandapip1";
          repo = "pam-ropc";
          rev = "840c2f8fe8e45215f106706a13569f88d086ac9e";
          hash = "sha256-MqKLN2AaQHowZxjNeiPPEW58o6fUbTpcRwRUwc+22Ok=";
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
