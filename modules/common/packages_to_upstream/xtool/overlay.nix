{
  nixpkgs.overlays = [
    (final: _: {
      # The Rust code-signing library (apple-codesign) that swift-rcodesign wraps,
      # built from the swift-rcodesign checkout itself. Upstream's Package.swift
      # downloads it prebuilt (an artifact bundle); package.nix points that at this.
      rcodesign-ffi =
        with final;
        rustPlatform.buildRustPackage {
          pname = "rcodesign-ffi";
          version = "0.2.0";
          inherit (xtool) src;

          cargoHash = "sha256-/Rz0y/XB0MimII0Vh6DwEF0uDsTXph2bt89p2PtHAoU=";

          # A static library only; there is nothing to run as tests here.
          doCheck = false;

          installPhase = ''
            runHook preInstall
            install -Dm644 -t "$out/lib" target/*/release/librcodesign_ffi.a 2>/dev/null \
              || install -Dm644 -t "$out/lib" target/release/librcodesign_ffi.a
            install -Dm644 -t "$out/include" include/rcodesign.h include/module.modulemap
            runHook postInstall
          '';
        };

      xtool =
        with final;
        # xtool (https://xtool.sh): builds and packs SwiftPM apps without Xcode. This
        # is the fork in src.nix, which adds macOS apps, asset catalogs and Icon
        # Composer icons (compiled by its CarKit, not Apple's actool).
        #
        # Built entirely from source. Two dependencies download prebuilt binaries by
        # default, and both are replaced:
        # - xtool-core's libimobiledevice, libplist, usbmuxd and OpenSSL frameworks:
        #   XTL_SYSTEM_LIBRARIES=1 makes it use nixpkgs' libraries instead.
        # - swift-rcodesign's Rust code-signing library: built by rcodesign.nix, and
        #   the checkout's manifest is patched to use it.

        let
          swiftPmDeps =
            let
              inherit (final)
                lib
                fetchgit
                ;
            in
            {
              pinData,
              overrides ? { },
              # Where SwiftPM keeps its state: .build, or a package's --scratch-path.
              scratchPath ? ".build",
              # Where Package.resolved goes: the package's root.
              packageRoot ? ".",
            }:

            let
              pins = pinData.deps;
              checkouts = lib.mapAttrs (
                name: pin:
                (overrides.${name} or lib.id) (fetchgit {
                  url = pin.location;
                  rev = pin.revision;
                  inherit (pin) hash;
                  fetchSubmodules = true;
                })
              ) pins;

              workspaceState = {
                version = 7;
                object = {
                  artifacts = [ ];
                  prebuilts = [ ];
                  dependencies = lib.mapAttrsToList (_: pin: {
                    basedOn = null;
                    packageRef = {
                      inherit (pin) identity name location;
                      kind = "remoteSourceControl";
                    };
                    state = {
                      name = "sourceControlCheckout";
                      checkoutState = { inherit (pin) revision version; };
                    };
                    inherit (pin) subpath;
                  }) pins;
                };
              };

              packageResolved = {
                version = 3;
                inherit (pinData) originHash;
                pins = lib.sortOn (p: p.identity) (
                  lib.mapAttrsToList (_: pin: {
                    inherit (pin) identity location;
                    kind = "remoteSourceControl";
                    state = { inherit (pin) revision version; };
                  }) pins
                );
              };
            in
            {
              inherit checkouts;

              # Shell commands that put the dependencies in place.
              configure = ''
                mkdir -p '${scratchPath}/checkouts'
                ${lib.concatStringsSep "\n" (
                  lib.mapAttrsToList (
                    name: pin: "ln -s ${checkouts.${name}} '${scratchPath}/checkouts/${pin.subpath}'"
                  ) pins
                )}
                install -m 0600 ${builtins.toFile "workspace-state.json" (builtins.toJSON workspaceState)} \
                  '${scratchPath}/workspace-state.json'
                install -m 0600 ${builtins.toFile "Package.resolved" (builtins.toJSON packageResolved)} \
                  '${packageRoot}/Package.resolved'
              '';
            };
          deps = swiftPmDeps {
            pinData = # xtool's SwiftPM dependency pins, mirroring its Package.resolved and
              # .build/workspace-state.json (see ../swiftpm-deps.nix for how they are used).
              #
              # To refresh after xtool's dependencies change: build xtool once with
              # `swift build`, then for each entry of .build/workspace-state.json take the
              # identity, name, location, revision, version and subpath, and get the hash
              # with `nurl <location> <revision> --json --submodules=true --fetcher=fetchgit`.
              {
                originHash = "2ccd077fc130f0f1b1279d87aa61d1fc243964d7ad49489a12021577c54df9de";
                deps = {
                  aexml = {
                    identity = "aexml";
                    name = "AEXML";
                    location = "https://github.com/tadija/AEXML.git";
                    revision = "dd9206de0717d658daec6a064992894fdab8ae17";
                    version = "4.7.3";
                    subpath = "AEXML";
                    hash = "sha256-FSXhRLKieM47f/5iJOuViqUGbR/g1LAm8q3wIgmuY5w=";
                  };
                  async-http-client = {
                    identity = "async-http-client";
                    name = "async-http-client";
                    location = "https://github.com/swift-server/async-http-client.git";
                    revision = "4c005f955e83f888d5616e579717a36d2dfc6301";
                    version = "1.36.2";
                    subpath = "async-http-client";
                    hash = "sha256-ZED/VVqSuth5o94gQXlEY9dpReC6E37CIEOciz5vjrw=";
                  };
                  bigint = {
                    identity = "bigint";
                    name = "BigInt";
                    location = "https://github.com/attaswift/BigInt";
                    revision = "63feef7820abb1a8fb08587d7da56bb0b7db8751";
                    version = "6.0.1";
                    subpath = "BigInt";
                    hash = "sha256-AKUSKkYDbbpObUlSzuk+LVBSYIqll90Z7lvtiJYdrng=";
                  };
                  combine-schedulers = {
                    identity = "combine-schedulers";
                    name = "combine-schedulers";
                    location = "https://github.com/pointfreeco/combine-schedulers";
                    revision = "114354e8c1667a2edc4993700fb9fa4f90157b56";
                    version = "1.2.2";
                    subpath = "combine-schedulers";
                    hash = "sha256-wTxGp9DnWdjbnyoUo1Zx39rwCbnN+rn5l3yd901kmEM=";
                  };
                  openapikit = {
                    identity = "openapikit";
                    name = "OpenAPIKit";
                    location = "https://github.com/mattpolzin/OpenAPIKit";
                    revision = "5b72eb9a6b23b1fec439d9a0bf38f115400421f9";
                    version = "6.4.0";
                    subpath = "OpenAPIKit";
                    hash = "sha256-N2q42+1ekN2g0+G01Ysn3i+19sjL8oIXpM7nhDQ17ug=";
                  };
                  opencombine = {
                    identity = "opencombine";
                    name = "OpenCombine";
                    location = "https://github.com/OpenCombine/OpenCombine.git";
                    revision = "8576f0d579b27020beccbccc3ea6844f3ddfc2c2";
                    version = "0.14.0";
                    subpath = "OpenCombine";
                    hash = "sha256-tw/WVY3TG8Jp+AO2rCA20x0u3lrg1wl7IaPkJXdfMzE=";
                  };
                  pathkit = {
                    identity = "pathkit";
                    name = "PathKit";
                    location = "https://github.com/kylef/PathKit.git";
                    revision = "3bfd2737b700b9a36565a8c94f4ad2b050a5e574";
                    version = "1.0.1";
                    subpath = "PathKit";
                    hash = "sha256-ewxTC1kpu6PXhwamCxYfI50ooYO1SIU0+IXH2tc/uv4=";
                  };
                  spectre = {
                    identity = "spectre";
                    name = "Spectre";
                    location = "https://github.com/kylef/Spectre.git";
                    revision = "26cc5e9ae0947092c7139ef7ba612e34646086c7";
                    version = "0.10.1";
                    subpath = "Spectre";
                    hash = "sha256-fipGRIgw+jV7Wrxa+xivRk7YMyxDhGFB6SHIHscrmV8=";
                  };
                  swift-algorithms = {
                    identity = "swift-algorithms";
                    name = "swift-algorithms";
                    location = "https://github.com/apple/swift-algorithms.git";
                    revision = "87e50f483c54e6efd60e885f7f5aa946cee68023";
                    version = "1.2.1";
                    subpath = "swift-algorithms";
                    hash = "sha256-cJfOxBB74V7ZE4g6OehYIdtmqYnSFIkJLpkxPo9jiUo=";
                  };
                  swift-argument-parser = {
                    identity = "swift-argument-parser";
                    name = "swift-argument-parser";
                    location = "https://github.com/apple/swift-argument-parser.git";
                    revision = "6a52f3251125d74daf04fcbd5e6f08a75d074382";
                    version = "1.8.2";
                    subpath = "swift-argument-parser";
                    hash = "sha256-BWm2ZbNIvlamNp8cxoicFlAcujjhH22VPzs67lEIXWU=";
                  };
                  swift-asn1 = {
                    identity = "swift-asn1";
                    name = "swift-asn1";
                    location = "https://github.com/apple/swift-asn1.git";
                    revision = "3b6410f7dee09eb33cdd26260c5fd47fda19b0e2";
                    version = "1.7.3";
                    subpath = "swift-asn1";
                    hash = "sha256-Y4MWePdGwLH8wVs9oFnwUUD7YU+WhOnT2rLyxgENIT8=";
                  };
                  swift-async-algorithms = {
                    identity = "swift-async-algorithms";
                    name = "swift-async-algorithms";
                    location = "https://github.com/apple/swift-async-algorithms.git";
                    revision = "13713a4ffdee8abd929f92568ee9462a46ae26e0";
                    version = "1.1.7";
                    subpath = "swift-async-algorithms";
                    hash = "sha256-Kt1wmMrxoaTLxr7uF+Ll6pHCc3nh2ayR1sp7yIm6Yms=";
                  };
                  swift-atomics = {
                    identity = "swift-atomics";
                    name = "swift-atomics";
                    location = "https://github.com/apple/swift-atomics.git";
                    revision = "0442cb5a3f98ab802acb777929fdb446bda11a34";
                    version = "1.3.1";
                    subpath = "swift-atomics";
                    hash = "sha256-ltWzlf0+XxMCR9xiFVGnQ35DueAp22mPRLadbTfnEPA=";
                  };
                  swift-certificates = {
                    identity = "swift-certificates";
                    name = "swift-certificates";
                    location = "https://github.com/apple/swift-certificates";
                    revision = "ff86b924ead66f853b8baf91f3c41926a8f36177";
                    version = "1.21.0";
                    subpath = "swift-certificates";
                    hash = "sha256-SF9V1ZzfgSGIYuTcA2BBFpe5vqcApPK5wpZuZ1IJ9mw=";
                  };
                  swift-clocks = {
                    identity = "swift-clocks";
                    name = "swift-clocks";
                    location = "https://github.com/pointfreeco/swift-clocks";
                    revision = "82440fa0a8b1c381a6d1e8e0fc7bbba53ec63204";
                    version = "1.1.1";
                    subpath = "swift-clocks";
                    hash = "sha256-prevuBLL8GD6YXzSnNjb8rcC0z9WDEXBB3X6WRTJi8U=";
                  };
                  swift-collections = {
                    identity = "swift-collections";
                    name = "swift-collections";
                    location = "https://github.com/apple/swift-collections";
                    revision = "35a1edcb8ebd2bfe251d587f0b69e62af28f508c";
                    version = "1.7.3";
                    subpath = "swift-collections";
                    hash = "sha256-2NgjGsOOwo+CZ1s92ftcdts4uk8a9JmP5SLvnmt7c6k=";
                  };
                  swift-concurrency-extras = {
                    identity = "swift-concurrency-extras";
                    name = "swift-concurrency-extras";
                    location = "https://github.com/pointfreeco/swift-concurrency-extras";
                    revision = "8a4260f7373493435bd21194585c95b72bfdd401";
                    version = "1.4.3";
                    subpath = "swift-concurrency-extras";
                    hash = "sha256-a2XFuAzXYx34zOu5UMJVi958ml5/cJf9vOW2YOHl448=";
                  };
                  swift-configuration = {
                    identity = "swift-configuration";
                    name = "swift-configuration";
                    location = "https://github.com/apple/swift-configuration.git";
                    revision = "8bae88f79dbddec793390c5bf3e2abb4ac2ece42";
                    version = "1.2.2";
                    subpath = "swift-configuration";
                    hash = "sha256-RcZtM+o9CWRIuXpv/r3bCIfKA5yisTlf+0YVngqayvY=";
                  };
                  swift-crypto = {
                    identity = "swift-crypto";
                    name = "swift-crypto";
                    location = "https://github.com/apple/swift-crypto";
                    revision = "c2cbadd7263439d8015189668f96ff5b5be565ce";
                    version = "5.0.3";
                    subpath = "swift-crypto";
                    hash = "sha256-572z0uIhOCmLTnQ/UI5tozzvTG0H2Vn4sA4hBCUF1q8=";
                  };
                  swift-custom-dump = {
                    identity = "swift-custom-dump";
                    name = "swift-custom-dump";
                    location = "https://github.com/pointfreeco/swift-custom-dump";
                    revision = "4fb9e7cbb4b8f5a7354005db39447f570d6b3e19";
                    version = "1.7.3";
                    subpath = "swift-custom-dump";
                    hash = "sha256-ULyM7VGhv2hoPDdNNTH3IMLmoWT+pe80TTX0LqJuPzM=";
                  };
                  swift-dependencies = {
                    identity = "swift-dependencies";
                    name = "swift-dependencies";
                    location = "https://github.com/pointfreeco/swift-dependencies";
                    revision = "b476cc5761057d8d857de063fe7ac8daecf5c06b";
                    version = "1.17.1";
                    subpath = "swift-dependencies";
                    hash = "sha256-nTwYdSGntBrkp3b4X7jlvB6WBObhJv+gaSJT9BuRkd4=";
                  };
                  swift-distributed-tracing = {
                    identity = "swift-distributed-tracing";
                    name = "swift-distributed-tracing";
                    location = "https://github.com/apple/swift-distributed-tracing.git";
                    revision = "297b5b9c82a5631e3199ce3ec0993a3cfb0fbb84";
                    version = "1.7.2";
                    subpath = "swift-distributed-tracing";
                    hash = "sha256-kTkf5v1yTtQTdBtft1PpcO/2lySvmO7S5v1oB7AenoU=";
                  };
                  swift-docc-plugin = {
                    identity = "swift-docc-plugin";
                    name = "SwiftDocCPlugin";
                    location = "https://github.com/swiftlang/swift-docc-plugin";
                    revision = "647c708be89f834fa6a6d4945442793a77ddf5b6";
                    version = "1.5.0";
                    subpath = "swift-docc-plugin";
                    hash = "sha256-BqtE2E75mI7c+BxxqDW9hvLxWxo2bbVul6kjA+/lCaI=";
                  };
                  swift-docc-symbolkit = {
                    identity = "swift-docc-symbolkit";
                    name = "SymbolKit";
                    location = "https://github.com/swiftlang/swift-docc-symbolkit";
                    revision = "b45d1f2ed151d057b54504d653e0da5552844e34";
                    version = "1.0.0";
                    subpath = "swift-docc-symbolkit";
                    hash = "sha256-+uQQiqVAon1UefkIM2FXwQIR5PVgR1K5e76Gvj4/g5M=";
                  };
                  swift-http-structured-headers = {
                    identity = "swift-http-structured-headers";
                    name = "swift-http-structured-headers";
                    location = "https://github.com/apple/swift-http-structured-headers.git";
                    revision = "933538faa42c432d385f02e07df0ace7c5ecfc47";
                    version = "1.7.0";
                    subpath = "swift-http-structured-headers";
                    hash = "sha256-mNMRXKnT/w6a12W3eHTzl4yEGNxJnnYzb7XvCfKsv3w=";
                  };
                  swift-http-types = {
                    identity = "swift-http-types";
                    name = "swift-http-types";
                    location = "https://github.com/apple/swift-http-types";
                    revision = "bff4b6903cdc99dda49649dd52f46c11cfd3ed50";
                    version = "1.8.0";
                    subpath = "swift-http-types";
                    hash = "sha256-OZGGDaUAhfhx5V6OpVn7HSfDE/FWJs9MO6c/FNELYdI=";
                  };
                  swift-issue-reporting = {
                    identity = "swift-issue-reporting";
                    name = "swift-issue-reporting";
                    location = "https://github.com/pointfreeco/swift-issue-reporting";
                    revision = "b23bb4493c439d3e05152bc167014235ba3d47fc";
                    version = "2.1.2";
                    subpath = "swift-issue-reporting";
                    hash = "sha256-wO+KRExHLa1V6iRXsQVsr/HUKShUGYVeHDE0O6CwPD0=";
                  };
                  swift-log = {
                    identity = "swift-log";
                    name = "swift-log";
                    location = "https://github.com/apple/swift-log.git";
                    revision = "4038b6a4f74a1426f47eb1dd5b4bb5628a15d597";
                    version = "1.16.1";
                    subpath = "swift-log";
                    hash = "sha256-WEyvnrPa6DnNnkVWHWJz1MbZrzQRNKt5hkqD3uCrY+Q=";
                  };
                  swift-nio-extras = {
                    identity = "swift-nio-extras";
                    name = "swift-nio-extras";
                    location = "https://github.com/apple/swift-nio-extras.git";
                    revision = "41449336c8ecfadac6b4b5be75f9c3c306e61ced";
                    version = "1.35.1";
                    subpath = "swift-nio-extras";
                    hash = "sha256-y6xy4zi88Awp7Ik3KDoWvd9eX+2wcxaPTLy2xUpht4M=";
                  };
                  swift-nio-http2 = {
                    identity = "swift-nio-http2";
                    name = "swift-nio-http2";
                    location = "https://github.com/apple/swift-nio-http2.git";
                    revision = "0f3e54e29c944c2e835ad52159da7d9e1c94ac69";
                    version = "1.46.0";
                    subpath = "swift-nio-http2";
                    hash = "sha256-L1XzyucVLxT94WK5Iq250IPgrbQWTgXnJg92zV7T5p8=";
                  };
                  swift-nio-ssl = {
                    identity = "swift-nio-ssl";
                    name = "swift-nio-ssl";
                    location = "https://github.com/apple/swift-nio-ssl.git";
                    revision = "322f3c2a4a21df31c84ca416bf65ee5e9059e440";
                    version = "2.37.5";
                    subpath = "swift-nio-ssl";
                    hash = "sha256-cRUqh0dQsRU+mqnwNUutcu49ZGnRUqaH+jDWpxd6da4=";
                  };
                  swift-nio-transport-services = {
                    identity = "swift-nio-transport-services";
                    name = "swift-nio-transport-services";
                    location = "https://github.com/apple/swift-nio-transport-services.git";
                    revision = "67787bb645a5e67d2edcdfbe48a216cc549222d5";
                    version = "1.28.0";
                    subpath = "swift-nio-transport-services";
                    hash = "sha256-BknmarVnZXK22UBJifB4uVWw0rZMNQiQSaZhsyrEO2c=";
                  };
                  swift-nio = {
                    identity = "swift-nio";
                    name = "swift-nio";
                    location = "https://github.com/apple/swift-nio";
                    revision = "6db9d9abd92ad7399b8a564cafbb87d3507245fa";
                    version = "2.104.0";
                    subpath = "swift-nio";
                    hash = "sha256-71tIcDb7LCYbSmcpShruIHnXHLZDollbnH7qVd9NWzM=";
                  };
                  swift-numerics = {
                    identity = "swift-numerics";
                    name = "swift-numerics";
                    location = "https://github.com/apple/swift-numerics.git";
                    revision = "0c0290ff6b24942dadb83a929ffaaa1481df04a2";
                    version = "1.1.1";
                    subpath = "swift-numerics";
                    hash = "sha256-bRkiRuxb4O3SmpsGZ5YaUR4cV3IQoES+u3xZTCzaQ+c=";
                  };
                  swift-openapi-async-http-client = {
                    identity = "swift-openapi-async-http-client";
                    name = "swift-openapi-async-http-client";
                    location = "https://github.com/swift-server/swift-openapi-async-http-client";
                    revision = "3681f659d9417652b8119f0adbdf57c04b6cb292";
                    version = "1.5.0";
                    subpath = "swift-openapi-async-http-client";
                    hash = "sha256-XDLFt4Dum2MsW+jKHVh+MSkpl9uxj/4fL65uEdDykuE=";
                  };
                  swift-openapi-generator = {
                    identity = "swift-openapi-generator";
                    name = "swift-openapi-generator";
                    location = "https://github.com/apple/swift-openapi-generator";
                    revision = "164dfbcf1f78e2ddc719ab9d85c50d1157fa8d7d";
                    version = "1.14.2";
                    subpath = "swift-openapi-generator";
                    hash = "sha256-gLxAQ0hWJ69s5qkYGxz7TiVdR5goy8jpRpt8PHcsqmk=";
                  };
                  swift-openapi-runtime = {
                    identity = "swift-openapi-runtime";
                    name = "swift-openapi-runtime";
                    location = "https://github.com/apple/swift-openapi-runtime";
                    revision = "ad7a252e215870ea2de9cf8605ff9336b004183a";
                    version = "1.13.1";
                    subpath = "swift-openapi-runtime";
                    hash = "sha256-b0MweesEdPwoX36+DB7+BUqKMzD8ojLSVebMPeit11A=";
                  };
                  swift-openapi-urlsession = {
                    identity = "swift-openapi-urlsession";
                    name = "swift-openapi-urlsession";
                    location = "https://github.com/apple/swift-openapi-urlsession";
                    revision = "c97e0f0187d95542b4a254f5bb4dc67f43bf73c9";
                    version = "1.4.0";
                    subpath = "swift-openapi-urlsession";
                    hash = "sha256-jqcOJbxN6QTu7ctSk/HwVRGsmJHJgkRX2djzHoaBZEs=";
                  };
                  swift-rcodesign = {
                    identity = "swift-rcodesign";
                    name = "swift-rcodesign";
                    location = "https://github.com/xtool-org/swift-rcodesign";
                    revision = "08650ab9d3bf95a0c585581b8bd63eb7b8315264";
                    version = "0.2.0";
                    subpath = "swift-rcodesign";
                    hash = "sha256-pHeN6Z8tIjHMq09opghwMEMNlvGt8Fd7XtA+g9dN2X0=";
                  };
                  swift-service-context = {
                    identity = "swift-service-context";
                    name = "swift-service-context";
                    location = "https://github.com/apple/swift-service-context.git";
                    revision = "853ba3d9ce78851b9cc20108e8bd4f13f7fa546c";
                    version = "1.5.1";
                    subpath = "swift-service-context";
                    hash = "sha256-R5fANpzSsKW0x7ydgKDTgt3OlEwjo/LJEnmrL4FM6IY=";
                  };
                  swift-service-lifecycle = {
                    identity = "swift-service-lifecycle";
                    name = "swift-service-lifecycle";
                    location = "https://github.com/swift-server/swift-service-lifecycle";
                    revision = "a18ee16b8039866fd919bdb4e8e906882d4ecc75";
                    version = "2.13.0";
                    subpath = "swift-service-lifecycle";
                    hash = "sha256-7nwFDeUFAGhasnJ0GKELTsu/i9spWBwuG8nVzG7znT4=";
                  };
                  swift-subprocess = {
                    identity = "swift-subprocess";
                    name = "swift-subprocess";
                    location = "https://github.com/swiftlang/swift-subprocess";
                    revision = "dbe21bd7dfd4ffef8c32588918542a8abfa1b54c";
                    version = "1.0.2";
                    subpath = "swift-subprocess";
                    hash = "sha256-0fNGzvPiMEeCr9tqg2bJHVsTIluWAk1MjRXqNYdvi+s=";
                  };
                  swift-syntax = {
                    identity = "swift-syntax";
                    name = "swift-syntax";
                    location = "https://github.com/swiftlang/swift-syntax";
                    revision = "050f1a346fbbac0ca2cfb15a95274f7bd1cf0ccf";
                    version = "604.0.0";
                    subpath = "swift-syntax";
                    hash = "sha256-qRs7x0c8RSIC7yXjUDnF6HaEhkWsXPeAoLa9Tc538cI=";
                  };
                  swift-system = {
                    identity = "swift-system";
                    name = "swift-system";
                    location = "https://github.com/apple/swift-system.git";
                    revision = "869129b7bf4ecc57b97d0193ad29690ca2134750";
                    version = "1.8.1";
                    subpath = "swift-system";
                    hash = "sha256-mnQcCHYW0oCadmIE9ayjs3aZiCVQRuliQ0qWpQ22OFQ=";
                  };
                  swiftymobiledevice = {
                    identity = "swiftymobiledevice";
                    name = "SwiftyMobileDevice";
                    location = "https://github.com/xtool-org/SwiftyMobileDevice";
                    revision = "1f6e4cc614a31953bda5d1092a747cfdea90916f";
                    version = "1.7.0";
                    subpath = "SwiftyMobileDevice";
                    hash = "sha256-weJbF89yUesLgToHraYo4mOMxwc+fccRIHnQWHxGX+0=";
                  };
                  unxip = {
                    identity = "unxip";
                    name = "unxip";
                    location = "https://github.com/saagarjha/unxip";
                    revision = "6c3990517fcc4c1db6952fccf4c562fb14097601";
                    version = "3.3.0";
                    subpath = "unxip";
                    hash = "sha256-+DYqb4Y2jqWEMungO+rE1UzMXLuAWAzsx6s0mbtOkR4=";
                  };
                  websocket-kit = {
                    identity = "websocket-kit";
                    name = "websocket-kit";
                    location = "https://github.com/vapor/websocket-kit.git";
                    revision = "90bbbdab3ede12c803cfbe91646f291c092517a3";
                    version = "2.16.2";
                    subpath = "websocket-kit";
                    hash = "sha256-rZhK8ggUqtUcwzvbZnWiNUBHFEWumpPD09kAwp6hims=";
                  };
                  xcode-project-format = {
                    identity = "xcode-project-format";
                    name = "xcode-project-format";
                    location = "https://github.com/apple/xcode-project-format.git";
                    revision = "c132630aabf40f6d6c3f7bb004595d2e5a28ea42";
                    version = "0.1.0";
                    subpath = "xcode-project-format";
                    hash = "sha256-67iV90c8c0PS5E2j7YAd5kv/dJOAmIosCpsOT3FkN0o=";
                  };
                  xcodeproj = {
                    identity = "xcodeproj";
                    name = "XcodeProj";
                    location = "https://github.com/tuist/XcodeProj.git";
                    revision = "b505c06bb190b9306b29d5d96e3284e139af3cc8";
                    version = "9.17.6";
                    subpath = "XcodeProj";
                    hash = "sha256-qOOId//lE7spo8Ib8bsdVl5O2QkzbIhDlQ20pC3A76s=";
                  };
                  xtool-core = {
                    identity = "xtool-core";
                    name = "xtool-core";
                    location = "https://github.com/xtool-org/xtool-core";
                    revision = "154d7213c12e3f21d50793f50ec7bfb89cfd3918";
                    version = "1.5.1";
                    subpath = "xtool-core";
                    hash = "sha256-OW8beGBLC5Qpdn0VnCjHmS/XJ/5uDsQgeYXc0QmkFoo=";
                  };
                  yams = {
                    identity = "yams";
                    name = "Yams";
                    location = "https://github.com/jpsim/Yams";
                    revision = "a27b21e0c81c5bf42049b897a62aaf387e80f279";
                    version = "6.2.2";
                    subpath = "Yams";
                    hash = "sha256-iOZsaPM4tn8/d8YBEvEJSGecwVkEXeON21SnkuysWrY=";
                  };
                };
              };
            overrides.swift-rcodesign =
              checkout:
              let
                library = final.rcodesign;
              in
              runCommand "swift-rcodesign-from-source" { nativeBuildInputs = [ perl ]; } ''
                cp -r ${checkout} $out
                chmod -R u+w $out
                # The library comes from rcodesign.nix rather than a download: a
                # system library module over its header, linked from there.
                perl -0pi -e 's/\.binaryTarget\(\s*name:\s*"RCodesignBinary".*?\)/.systemLibrary(name: "RCodesignBinary", path: "include")/s' \
                  $out/Package.swift
                grep -q 'systemLibrary(name: "RCodesignBinary"' $out/Package.swift
                ! grep -q binaryTarget $out/Package.swift
                cat > $out/include/module.modulemap <<'MAP'
                module RCodesignBinary [extern_c] {
                    header "rcodesign.h"
                    link "rcodesign_ffi"
                    export *
                }
                MAP
                mkdir -p $out/lib && ln -s ${library}/lib/librcodesign_ffi.a $out/lib/
              '';
          };
        in
        stdenv.mkDerivation {
          pname = "xtool";
          version = "0-unstable-2026-11-12";

          src = fetchFromGitHub {
            owner = "Pandapip1";
            repo = "xtool";
            rev = "7d44346878ca033ed79ad2312c5b8ed3a16bf503";
            hash = "sha256-rxR7SrnPhfXk1iGFAI7wzI5efbmt585rJzHl+iX2dp4=";
          };

          nativeBuildInputs = [
            swift
            swiftpm
            pkg-config
            makeWrapper
            writableTmpDirAsHomeHook
          ];
          buildInputs = [
            libimobiledevice
            libimobiledevice-glue
            libplist
            libusbmuxd
            openssl
            zlib
          ];

          env.XTL_SYSTEM_LIBRARIES = "1";

          # Adding xtool to a package's nativeBuildInputs builds it as an xtool app;
          # see setup-hook.sh.
          setupHook = replaceVars ./setup-hook.sh {
            rcodesign = lib.getExe rcodesign;
          };

          configurePhase = ''
            runHook preConfigure
            ${deps.configure}
            # rcodesign's static library, linked by its module map's `link`.
            export LIBRARY_PATH="$PWD/.build/checkouts/swift-rcodesign/lib''${LIBRARY_PATH:+:$LIBRARY_PATH}"
            runHook postConfigure
          '';

          buildPhase = ''
            runHook preBuild
            # No prebuilt swift-syntax for macros: SwiftPM would try to download it
            # (and, failing to in the sandbox, exit with an error after building).
            swift build -c release --product xtool --build-system native \
              --disable-sandbox --disable-automatic-resolution --skip-update \
              --disable-experimental-prebuilts
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            install -Dm755 .build/release/xtool "$out/bin/xtool"
            # xtool runs SwiftPM, which signs what it links with codesign (here
            # sigtool's), and renders SVGs (asset catalogs, icons) with resvg.
            wrapProgram "$out/bin/xtool" \
              --suffix PATH : ${
                lib.makeBinPath [
                  swift
                  swiftpm
                  resvg
                  darwin.sigtool
                ]
              }
            runHook postInstall
          '';

          meta = {
            description = "Cross-platform Xcode replacement: build and pack SwiftPM apps without Xcode";
            homepage = "https://github.com/Pandapip1/xtool";
            license = lib.licenses.mit;
            platforms = lib.platforms.darwin;
            mainProgram = "xtool";
          };
        };
    })
  ];
}
