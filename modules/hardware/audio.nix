{
  lib,
  pkgs,
  ...
}:

{
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    alsa.support32Bit = pkgs.stdenvNoCC.hostPlatform.isx86_64;
    pulse.enable = true;
    jack.enable = true;
    # systemWide = true; # Not the default and not recommended but makes the most sense to me.
  };

  # Required for system-wide audio to work for normal users
  /* users.commonGroups.normal = [
    "pipewire"
  ]; */
}
