{
  nixpkgs.overlays = [
    (final: prev: {
      # ccid = prev.ccid.overrideAttrs (old: {
      #   src = final.fetchFromGitHub {
      #     owner = "LudovicRousseau";
      #     repo = "CCID";
      #     rev = "8d7e34c704a82f3c7c7ee02f8ba496fd2b2b0c33";
      #   };
      # });

      # pcsclite = prev.pcsclite.overrideAttrs (old: {
      #   src = final.fetchFromGitHub {
      #     owner = "LudovicRousseau";
      #     repo = "PCSC";
      #     rev = "c4a2e9900abc9a0d9bee5f025edc7d9c44820ddb";
      #   };
      # });
    })
  ];
  systemd.services.pcscd.environment.LIBCCID_ifdLogLevel = "0x000F";
  services.pcscd.extraArgs = [
    "--debug"
    "--apdu"
    "--color"
  ];
}
