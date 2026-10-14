{
  lib,
  ...
}:

{
  networking = {
    firewall.enable = lib.mkForce true;
    nftables.enable = true;
  };
}
