{
  config,
  pkgs,
  ...
}:

{
  networking.nameservers = [
    "127.0.0.1"
    "::1"
  ];

  services = {
    unbound = {
      enable = true;
      resolveLocalQueries = false;
      package = pkgs.unbound-full;
      settings = config.localDns.unboundSettings;
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
  services.tor = {
    enable = true;
    client = {
      enable = true;
      dns.enable = true;
    };
  };
}
