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
    };
  };
  # Cursed cursed so deeply cursed
  # To get local playback I route via a localhost snapserver eek
  services.snapserver = {
    enable = true;
    settings.stream.source = "tcp://0.0.0.0?port=4953&name=snapbroadcast";
  };
}
