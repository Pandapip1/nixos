{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./audio.nix
    ./matter.nix
    ./esphome.nix
    ./ai.nix
  ];

  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      "tile"
      "moon"
      "sun"
      "zha"
      "zone"
      "mobile_app"
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
      device_tracker = [
        {
          platform = "luci";
          host = "192.168.1.1";
          username = "hassuser";
          password = "TODO";
        }
      ];
      mobile_app = {};
    };
  };
}
