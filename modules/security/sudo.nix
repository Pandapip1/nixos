{
  config,
  lib,
  ...
}:

{
  # When we're using SSH keys, NOPASSWD is needed
  security.sudo.wheelNeedsPassword = lib.mkIf config.services.openssh.enable (lib.mkForce false);

  # Use sudo-rs instead of sudo
  security.sudo-rs.enable = true;
  security.sudo.enable = false;
}
