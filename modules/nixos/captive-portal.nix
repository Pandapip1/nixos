{
  lib,
  config,
  pkgs,
  ...
}:

# Logging in to captive portals. Recursive DNS goes through Tor (see
# security/dns.nix), which can't work until the portal is accepted, and
# portals often redirect to their own host names that only the network's own
# DNS knows. `captive-browser` opens a WebKit window (packages/captive-portal)
# whose lookups and connections go through a SOCKS proxy that uses the
# network's DHCP-provided DNS server directly, bypassing the local resolver.
lib.mkIf (config.services.graphical-desktop.enable && !(config.optimizations.lean.enable)) {
  programs.captive-browser = {
    enable = true;
    browser = lib.getExe pkgs.captive-portal;
    # Which interface is up varies per host; ask NetworkManager for the DNS
    # servers of every device instead of binding to one.
    bindInterface = false;
  };
}
