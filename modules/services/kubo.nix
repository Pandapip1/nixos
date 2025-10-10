{
  lib,
  ...
}:

{
  services.kubo = {
    enable = lib.mkDefault true;
    autoMount = lib.mkDefault true;
    enableGC = lib.mkDefault true;
    localDiscovery = lib.mkDefault false;
    # Use port 4030 by default (leave port 8080 alone)
    # This isn't standard, and was chosen because it's kinda near 4000, which is also used by ipfs
    settings.Addresses.Gateway = lib.mkDefault [
      "/ip4/127.0.0.1/tcp/4030"
      "/ip6/::1/tcp/4030"
    ];
  };
}
