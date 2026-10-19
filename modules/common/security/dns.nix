{ lib, pkgs, ... }:

{
  options.localDns.unboundSettings = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    internal = true;
  };

  config.localDns.unboundSettings = {
    server = {
      interface = [
        "127.0.0.1"
        "::1"
      ];
      port = 53;
      verbosity = 1;
      root-hints = "${pkgs.dns-root-data}/root.hints";

      # Permit the Tor DNSPort used by the onion forward zone below.
      do-not-query-localhost = false;

      # Disable strict DNSSEC validation for the merged OpenNIC root.
      val-permissive-mode = "yes";

      # Override RFC7686 so .onion queries can reach Tor's DNSPort.
      local-zone = [ ''"onion." nodefault'' ];
      domain-insecure = [ "onion" ];
      private-domain = [ "onion" ];
    };

    forward-zone = [
      {
        name = "onion";
        forward-addr = [ "127.0.0.1@9053" ];
      }
    ];
  };
}
