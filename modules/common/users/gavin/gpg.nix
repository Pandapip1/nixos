{
  # Public half of the OpenPGP hardware key. Without it in the keyring,
  # gpg cannot use the card (git signing and the SSH auth subkey both
  # fail) until someone imports it by hand on each new machine.
  home-manager.users.gavin = {
    programs.gpg = {
      enable = true;
      publicKeys = [
        {
          source = ./gpg-public-key.asc;
          trust = "ultimate";
        }
      ];
    };

    programs.git.signing.key = "F11A59B7C2694772B43CD531EFDD7A7049E20963";
  };

  # SSH logins (on hosts running sshd) with the authentication subkeys of
  # this key, refreshed from the keyserver: a new subkey works without a
  # rebuild. See modules/common/security/gpg-authorized-keys.nix.
  users.users.gavin.gpgAuthorizedKeys = {
    primary = "F11A59B7C2694772B43CD531EFDD7A7049E20963";
    seedKeys = [ ./gpg-public-key.asc ];
  };
}
