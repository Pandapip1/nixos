{
  pkgs,
  ...
}:

{
  # A small aarch64-linux NixOS VM that nix-daemon offloads Linux builds to,
  # since macOS cannot run Linux binaries via binfmt. NixOS tests still run
  # their VMs on the Mac itself (apple-virt); this only builds the guests.
  # Bootstrapping it the first time requires the binary cache.
  nix.linux-builder = {
    enable = true;
    ephemeral = true;
    maxJobs = 4;
    # Run the guest on Virtualization.framework (vzvm) instead of QEMU, so that
    # x86_64-linux builds go through Rosetta rather than QEMU user-mode
    # emulation. QEMU user-mode could not run Quartus (segfault loading its
    # device database), and its x86_64 bwrap cannot create user namespaces.
    # Keeps the `<hostname>.qcow2` disk name, SSH port and host key, so the
    # nix-darwin module (ephemeral wipe, buildMachines entry) works unchanged.
    package = pkgs.darwin.linux-builder-vz;
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    config.virtualisation = {
      cores = 6;
      # Rosetta registers the x86_64-linux binfmt handler itself (on by
      # default for the vz builder); no boot.binfmt.emulatedSystems.
      vz.rosetta.enable = true;
      darwin-builder = {
        memorySize = 8 * 1024;
        diskSize = 40 * 1024;
      };
    };
  };
}
