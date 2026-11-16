{
  pkgs,
  ...
}:

let
  # gvproxy's socket for the guest's network link. Inside the builder's
  # working directory, so it is root's and short enough for sockaddr_un.
  gvproxySocket = "/var/lib/linux-builder/gvproxy.sock";

  # vzvm with a "unixgram" network mode, so the guest's network can come from
  # gvproxy instead of Virtualization.framework's NAT (see below).
  vzvm = pkgs.vzvm.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [
      ../../packages/vzvm/0001-Let-the-guest-network-use-a-user-mode-stack-instead-.patch
    ];
    # The package builds from the repository's vzvm/ directory; the patch's
    # paths start at the repository root.
    patchFlags = [ "-p2" ];
  });
in
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
      vz.package = vzvm;
      # Virtualization.framework's NAT is macOS Internet Sharing, which turns
      # on IP forwarding and loads its own pf ruleset with `set skip on lo0`.
      # That disables the pf redirect that carries BIND's DNS through Tor
      # (modules/darwin/dns.nix). gvproxy gives the guest DHCP, DNS and
      # outbound NAT in user space instead, touching nothing on the host.
      vz.extraConfig.network = {
        mode = "unixgram";
        path = gvproxySocket;
      };
      darwin-builder = {
        memorySize = 8 * 1024;
        diskSize = 40 * 1024;
      };
    };
  };

  # The guest's network: DHCP on 192.168.127.0/24, with gvproxy as gateway and
  # DNS server. SSH reaches the guest over vsock, so no host port forwards
  # (-ssh-port -1 drops gvproxy's default one).
  launchd.daemons.linux-builder-gvproxy.serviceConfig = {
    ProgramArguments = [
      "/bin/sh"
      "-c"
      "/bin/wait4path /nix/store && exec ${pkgs.gvproxy}/bin/gvproxy -ssh-port -1 -listen-vfkit unixgram://${gvproxySocket}"
    ];
    RunAtLoad = true;
    KeepAlive = true;
    WorkingDirectory = "/var/lib/linux-builder";
    StandardErrorPath = "/var/log/linux-builder-gvproxy.log";
  };
}
