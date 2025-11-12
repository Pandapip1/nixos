{
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      "default_config"
      "esphome"
      "tile"
      "matter"
      "mcp_server"
      "moon"
      "sun"
      "zha"
      "zone"
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
          "[::]"
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
}
