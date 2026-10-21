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
    config.virtualisation = {
      cores = 6;
      darwin-builder = {
        memorySize = 8 * 1024;
        diskSize = 40 * 1024;
      };
    };
  };
}
