{
  services = {
    unbound = {
      enable = true;
      resolveLocalQueries = false; # We are doing this through resolved
      settings = {
        server = {
          interface = [ "::1" ];
          port = 5354; # 5353 used by avahi
          verbosity = 1;
        };
      };
    };
    # TODO: Create & upstream option to configure port
    avahi = {
      enable = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
      # Take over mDNS resolving responsibilities
      nssmdns4 = true;
      nssmdns6 = true;
    };
  };
  resolved = {
    enable = true;
    llmnr = "false"; # Handled by avahi
    dns = [
      "[::1]:5354" # Unbound
    ];
    fallbackDns = [ ]; # Disable fallback for security

    # Unbound supports DNSSEC and DNS over TLS. Might as well revalidate, doesn't cost that much.
    dnssec = "allow-downgrade";
    dnsovertls = "opportunistic"; 
  };
}
