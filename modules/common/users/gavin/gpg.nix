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
}
