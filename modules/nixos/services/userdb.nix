{
  lib,
  ...
}:

{
  # Needed for DynamicUser + SupplementaryGroups
  services.userdbd.enable = true;

  ids.uids.nixbld = lib.mkForce 500;
}
