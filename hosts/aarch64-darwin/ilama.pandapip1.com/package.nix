{
  pkgs,
  ...
}:

{
  networking = {
    computerName = "Gavin’s MacBook Neo";
    knownNetworkServices = [ "Wi-Fi" ];
    localHostName = "Gavins-MacBook-Neo";
  };

  users.users.gavin = {
    home = "/Users/gavin";
    uid = 501;
  };
  system.primaryUser = "gavin";

  environment.systemPackages = with pkgs; [
    ext4fuse
    vim
    vscodium
  ];

  # Matches the fresh Nix install (nixbld gid 350).
  system.stateVersion = 6;
}
