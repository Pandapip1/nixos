{
  services = {
    unbound = {
      enable = true;
      resolveLocalQueries = true;
      settings = {
        server = {
          interface = [ "::" ];
          port = 53;
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
}
