{
  pkgs,
  ...
}:

{
  networking = {
    computerName = "Gavin’s MacBook Neo";
    # Every network service whose DNS nix-darwin should set (networking.dns).
    # One left out uses its network's DNS servers, bypassing the local
    # resolver and Tor.
    knownNetworkServices = [
      "Wi-Fi"
      "USB 10/100/1000 LAN"
    ];
    localHostName = "Gavins-MacBook-Neo";
  };

  users.users.gavin = {
    home = "/Users/gavin";
    uid = 501;
  };
  system.primaryUser = "gavin";

  environment.systemPackages = with pkgs; [
    ext4fuse
    xcodebuildmcp
    vim
    vscodium
  ];

  # Matches the fresh Nix install (nixbld gid 350).
  system.stateVersion = 6;
}
