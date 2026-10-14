{
  pkgs,
  ...
}:

{
  networking = {
    computerName = "Gavin’s MacBook Pro";
    knownNetworkServices = [ "Wi-Fi" ];
    localHostName = "Gavins-MacBook-Pro";
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

  nix = {
    channel.enable = false;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Preserve the version used by this Mac's existing bootstrap configuration.
  system.stateVersion = 6;
}
