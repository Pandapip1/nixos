{
  nixpkgs.overlays = [
    (self: super: {
      fido2-hid-bridge = super.callPackage (
        {
          lib,
          python3Packages,
          fetchFromGitHub,
          nix-update-script,
        }:

        python3Packages.buildPythonApplication {
          pname = "fido2-hid-bridge";
          version = "0-unstable-2024-11-18";
          pyproject = true;

          src = fetchFromGitHub {
            owner = "BryanJacobs";
            repo = "fido2-hid-bridge";
            rev = "52d0911054e74f22c4e9e726e8bc24a72cda178d";
            hash = "sha256-KbrGyi2L5hvZRplXYTqLd7dbTFf9eM+5aXbv0dXpDsM=";
          };

          strictDeps = true;
          __structuredAttrs = true;

          build-system = with python3Packages; [ poetry-core ];
          dependencies =
            with python3Packages;
            (
              [
                (super.python3Packages.callPackage (
                  {
                    lib,
                    buildPythonPackage,
                    fetchFromGitHub,
                    setuptools,
                    nix-update-script,
                  }:

                  buildPythonPackage {
                    pname = "uhid";
                    version = "0-unstable-2021-04-08";
                    pyproject = true;

                    src = fetchFromGitHub {
                      owner = "FFY00";
                      repo = "python-uhid";
                      rev = "99f459aef3934a146d1954ae372b1a107b1f34eb";
                      hash = "sha256-QTTlSYaDciWc9I/MUvR9YJ9z4oxHeN/PLJ3rcJhRd/w=";
                    };

                    build-system = [ setuptools ];

                    pythonImportsCheck = [ "uhid" ];

                    passthru.updateScript = nix-update-script {
                      extraArgs = [ "--version=branch" ];
                    };

                    meta = {
                      description = "Pure Python typed Linux UHID wrapper";
                      homepage = "https://github.com/FFY00/python-uhid";
                      license = lib.licenses.mit;
                      platforms = lib.platforms.linux;
                      maintainers = with lib.maintainers; [ pandapip1 ];
                    };
                  }
                ) { })
                fido2
                pyscard
              ]
              ++ fido2.optional-dependencies.pcsc
            );

          doCheck = false;

          passthru.updateScript = nix-update-script {
            extraArgs = [ "--version=branch" ];
          };

          meta = {
            description = "HID to PC/SC bridge allowing browsers to use FIDO2 smartcards";
            homepage = "https://github.com/BryanJacobs/fido2-hid-bridge";
            license = lib.licenses.mit;
            mainProgram = "fido2-hid-bridge";
            platforms = lib.platforms.linux;
            maintainers = with lib.maintainers; [ pandapip1 ];
          };
        }
      ) { };
    })
  ];
}
