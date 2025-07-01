# This module is just always on, /etc/secrets should always exist and be (mostly) readonly
{
  systemd.services.etc-secrets-permissions = {
    description = "Ensure permissions on /etc/secrets";
    wantedBy = [ "multi-user.target" ];
    before = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /etc/secrets
      chown -R root:root /etc/secrets
      find /etc/secrets -type f -exec chmod 400 {} \;
      find /etc/secrets -type d -exec chmod 500 {} \;
    '';
  };
}
