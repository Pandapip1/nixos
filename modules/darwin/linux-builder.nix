{
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
    # The same ARM VM also builds x86_64 Linux, through QEMU user-mode
    # emulation inside the guest. (Rosetta would be faster, but it is only
    # offered to Virtualization.framework VMs; this builder runs under QEMU.)
    # Slow, so meant for small builds whose dependencies come from the cache.
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    config.boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
    config.virtualisation = {
      cores = 6;
      darwin-builder = {
        memorySize = 8 * 1024;
        diskSize = 40 * 1024;
      };
    };
  };
}
