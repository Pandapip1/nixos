{
  lib,
  pkgs,
  ...
}:

{
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraPackages = python3packages: with python3packages; [
      gtts
      zlib-ng
      isal
      caldav
      python-otbr-api
      snapcast
      mpd2
    ];
    extraComponents = [
      "esphome"
      "tile"
      "matter"
      "mcp_server"
      "moon"
      "sun"
      "zha"
      "zone"
      "mobile_app"
      "snapcast"
      "dlna_dmr"
    ];
    lovelaceConfig = {
      title = "My Home";
      views = [
        {
          title = "Test View";
          cards = [
            {
              type = "markdown";
              title = "Test Card";
              content = "Test content";
            }
          ];
        }
      ];
    };
    config = {
      http = {
        server_host = [
          "::"
          "0.0.0.0"
        ];
        server_port = 8123;
      };
      homeassistant = {
        unit_system = "metric";
        latitude = 34.1391;
        longitude = -118.1255;
      };
      media_player = [
        {
          platform = "vlc";
        }
      ];
    };
  };
  systemd.user.services.vlc = {
    enable = true;
    description = "VLC Media Player";
    wantedBy = [
      "default.target"
    ];
    after = [
      "default.target"
      "pipewire.service"
      "pipewire-pulse.service"
    ];
    wants = [
      "pipewire.service"
      "pipewire-pulse.service"
    ];

    serviceConfig = {
      ExecStart = ''
        ${lib.getExe pkgs.vlc} \
        --intf dummy \
        --rc-host=localhost:4212
      '';
      Restart = "always";
    };
  };
  users.users.hass.extraGroups = [ "audio" ];
}
