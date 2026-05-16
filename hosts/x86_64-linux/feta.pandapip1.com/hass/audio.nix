{
  services.home-assistant = {
    extraComponents = [
      "media_source"
    ];
    config = {
      media_player = [
        {
          platform = "vlc";
        }
      ];
      media_source = {};
    };
  };

  users.users.hass.extraGroups = [
    "audio"
  ];
}
