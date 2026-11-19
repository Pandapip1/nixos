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
          forceFetchGit = true; # Codeberg temporary outage
          hash = "sha256-MqKLN2AaQHowZxjNeiPPEW58o6fUbTpcRwRUwc+22Ok=";
        };

        cargoLock = {
          lockFile = finalAttrs.src + "/Cargo.lock";
          allowBuiltinFetchGit = true;
        };

        nativeBuildInputs = with prev; [ pkg-config ];
        buildInputs = with prev; [
          libsodium
          pam
        ];

        # On aarch64-linux
        #  >
        #  > thread 'http_client_tests::build_http_client_with_timeout' (134458) panicked at src/lib.rs:261:67:
        #  > called `Result::unwrap()` on an `Err` value: reqwest::Error { kind: Request, url: "http://127.0.0.1:38671/hello", source: TimedOut }
        #  > note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
        #  >
        #  >
        #  > failures:
        #  >     http_client_tests::build_http_client_with_timeout
        dontCheck = true;

        postInstall = ''
          mkdir -p $out/lib/security
          ln -s $out/lib/libpam_ropc.so $out/lib/security/pam_ropc.so
        '';
      });
    })
  ];
}
