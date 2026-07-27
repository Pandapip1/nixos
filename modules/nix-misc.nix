{
  lib,
  config,
  pkgs,
  self,
  nixpkgs,
  nur,
  ...
}:

{
  imports = [
    (
      {
        config,
        lib,
        pkgs,
        nixpkgs,
        ...
      }:

      {
        disko.imageBuilder = {
          enableBinfmt = true;
          pkgs = lib.mkDefault pkgs;
          kernelPackages = lib.mkDefault pkgs.linuxPackages;
          qemu =
            # override loglevel=8 to help with debugging (loglevel 4 is hardcoded)
            let
              qemu-common = pkgs.callPackage "${pkgs.path}/nixos/lib/qemu-common.nix" { };
            in
            pkgs.writeShellScript "qemu-verbose" ''
              set -euo pipefail
              args=()
              while [ "$#" -gt 0 ]; do
                if [ "$1" = "-append" ]; then
                  args+=(
                    "-append"
                    "$(printf '%s' "$2" | ${lib.getExe' pkgs.gnused "sed"} -E 's/(^| )loglevel=[0-9]+/\1loglevel=8/')"
                  )
                  shift 2
                else
                  args+=("$1")
                  shift
                fi
              done
              exec ${qemu-common.qemuBinary pkgs.qemu_kvm} "''${args[@]}"
            '';
        };
      }
    )
  ];

  # virtiofsd <=1.14.0 only checks the legacy STATX_MNT_ID statx bit, not
  # STATX_MNT_ID_UNIQUE. On build hosts whose kernel has stopped setting the
  # legacy bit, every mount ID lookup comes back as 0, tripping virtiofsd's
  # submount-swap check ("Mount point's ... mount ID (0) does not match
  # expected value") and breaking disko's diskoImages VM builder.
  # --inode-file-handles=never skips that check entirely (falls back to
  # O_PATH fds instead of file handles).
  nixpkgs.overlays = [
    (final: prev: {
      virtiofsd = prev.runCommand "virtiofsd-wrapped" { nativeBuildInputs = [ prev.makeWrapper ]; } ''
        makeWrapper ${lib.getExe prev.virtiofsd} $out/bin/${prev.virtiofsd.meta.mainProgram} \
          --add-flags "--inode-file-handles=never"
      '';
    })
  ];

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    channel.enable = false;
    package = pkgs.nixVersions.latest;
    nixPath = lib.mkForce [
      "nixpkgs=flake:nixpkgs"
      "nur=flake:nur"
      # `nix-instantiate --eval -E '(import <config>)'` will get the config for the current machine
      "config=${pkgs.writeText "configuration.nix" "(builtins.getFlake (toString ${self.outPath})).nixosConfigurations.${config.networking.hostName}.config"}"
    ];
    registry =
      let
        mkRegistryEntry = name: path: {
          ${name}.to = {
            type = "path";
            inherit path;
            narHash = builtins.readFile (
              pkgs.buildPackages.runCommandLocal "get-${name}-hash" { }
                "${lib.getExe' pkgs.buildPackages.nix "nix-hash"} --type sha256 --sri ${path} > $out"
            );
          };
        };
      in
      mkRegistryEntry "nixpkgs" pkgs.path // mkRegistryEntry "nur" nur.outPath;
  };

  nixpkgs = {
    flake = {
      source = nixpkgs.outPath;
      setFlakeRegistry = false; # We do this ourselves
      setNixPath = false; # Again, we do this ourselves
    };
    config.warnUndeclaredOptions = true;
  };

  boot.binfmt.emulatedSystems = lib.remove pkgs.hostPlatform.system [
    "aarch64-linux"
    "x86_64-linux"
  ];
}
