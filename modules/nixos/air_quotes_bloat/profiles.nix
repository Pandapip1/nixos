{
  # Expensive programs; only keep a single generation
  extraProfiles.singleton.enable = true;
  nix-gc.profiles.singleton.configurationLimit = 1;
}
