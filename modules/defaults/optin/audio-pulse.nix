{
  config,
  lib,
  ...
}:

{
  options = {
    defaults.audio = lib.mkEnableOption "audio defaults";
  };

  config = lib.mkIf config.defaults.audio {
    services.pipewire = {
      audio.enable = true;
      alsa.enable = true;
      jack.enable = true;
      pulse.enable = true;
      # systemWide = true; # Not the default and not recommended but makes the most sense to me.
    };

    # Required for system-wide audio to work for normal users
    /* users.commonGroups.normal = [
      "pipewire"
    ]; */
  };
}
