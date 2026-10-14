{
  lib,
  pkgs,
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
            toString (
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
                ${qemu-common.qemuBinary pkgs.qemu_kvm} "''${args[@]}" 2>&1 \
                  | ${lib.getExe' pkgs.gnused "sed"} -u 's/\r//g'
              ''
            );
        };
      }
    )
  ];

  boot.binfmt.emulatedSystems = lib.remove pkgs.hostPlatform.system [
    "aarch64-linux"
    "x86_64-linux"
  ];
}
