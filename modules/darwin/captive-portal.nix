{
  lib,
  pkgs,
  ...
}:

# Logging in to captive portals; see modules/nixos/captive-portal.nix. macOS
# has no captive-browser module, so this builds the same wrapper by hand.
let
  # DNS servers from the DHCP lease of the interface carrying the default
  # route (all of them, unlike `ipconfig getoption`).
  dhcpDns = pkgs.writeShellScript "captive-browser-dhcp-dns" ''
    iface=$(/sbin/route -n get default 2>/dev/null | /usr/bin/awk '$1 == "interface:" { print $2; exit }')
    /usr/sbin/ipconfig getpacket "''${iface:-en0}" 2>/dev/null |
      /usr/bin/awk -F '[{}]' '/domain_name_server/ { gsub(/,/, " ", $2); print $2 }'
  '';
  configDir = pkgs.writeTextDir "captive-browser.toml" ''
    browser = """${lib.getExe pkgs.captive-portal}"""
    dhcp-dns = """${dhcpDns}"""
    socks5-addr = """localhost:1666"""
  '';
  captive-browser = pkgs.writeShellScriptBin "captive-browser" ''
    export XDG_CONFIG_HOME=${configDir}
    exec ${lib.getExe pkgs.captive-browser} "$@"
  '';
in
{
  environment.systemPackages = [ captive-browser ];

  # macOS's own sign-in sheet (Captive Network Assistant) resolves through the
  # system resolver, so it can't reach portals once DNS goes through Tor. Turn
  # it off; run `captive-browser` when a network needs a login.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    /usr/bin/defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false
  '';
}
