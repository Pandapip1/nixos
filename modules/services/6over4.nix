{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.nebula.networks.nebula0;
  ip = lib.getExe pkgs.iproute2;
  awk = lib.getExe' pkgs.gawk "awk";
  # ULA prefix for nebula overlay
  ula_prefix = "fd00:cafe:beef:1";
  # Derive ULA address from nebula IPv4 last octet at runtime
  startScript = pkgs.writeShellScript "neb6-start" ''
    set -e
    NEBULA_IP=$(${ip} -4 addr show nebula.nebula0 | ${awk} '/inet / {print $2}' | cut -d/ -f1)
    LAST_OCTET=$(echo "$NEBULA_IP" | cut -d. -f4)
    ULA="${ula_prefix}::$LAST_OCTET"

    # Clean up any leftover state
    ${ip} tunnel del neb6 2>/dev/null || true

    ${ip} tunnel add neb6 mode sit local "$NEBULA_IP" remote 10.0.0.1 ttl 64
    ${ip} link set neb6 mtu 1280 up
    ${ip} -6 addr add "$ULA/64" dev neb6
    ${ip} -6 route add ::/0 via ${ula_prefix}::1 dev neb6
  '';
  stopScript = pkgs.writeShellScript "neb6-stop" ''
    ${ip} link set neb6 down 2>/dev/null || true
    ${ip} tunnel del neb6 2>/dev/null || true
  '';
in
lib.mkIf cfg.enable {
  systemd.services.neb6 = {
    enable = true;
    description = "IPv6-over-IPv4 (sit) tunnel over nebula overlay";
    after = [ "nebula@nebula0.service" ];
    bindsTo = [ "nebula@nebula0.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${startScript}";
      ExecStop = "${stopScript}";
    };
  };

  # Tell NetworkManager to leave neb6 and nebula0 alone
  networking.networkmanager.unmanaged = lib.mkIf config.networking.networkmanager.enable [
    "nebula0"
    "neb6"
  ];
}
