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
    wireplumber.enable = true;
    systemWide = true; # Not the default and not recommended but makes the most sense to me.
  };
  # Update the socket groups so pipewire doesn't have to be added to every user
  systemd.user.sockets.pipewire.socketConfig.SocketGroup = "audio";
  systemd.user.sockets.pipewire-pulse.socketConfig.SocketGroup = "audio";
  systemd.sockets.pipewire.socketConfig.SocketGroup = "audio";
  systemd.sockets.pipewire-pulse.socketConfig.SocketGroup = "audio";

  # Required for system-wide audio to work for normal users
  /* users.commonGroups.normal = [
    "pipewire"
  ]; */
}
