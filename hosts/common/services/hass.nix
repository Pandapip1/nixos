{ config, lib, pkgs, nix-software-center, nixos-conf-editor, ... }:

{
  environment.systemPackages = with pkgs; [
    home-assistant
    home-assistant-cli
    # For CUPS integration
    python311
    python311Packages.pycups
    gcc
  ];
  networking.firewall.allowedTCPPorts = [ 8123 ];
  services.home-assistant = {
    enable = true;
    extraComponents = [
      # Home Assitant APIs
      "http"
      "api"
      "websocket_api"
      "rss_feed_template"
      # Utilities
      "alert"
      "counter"
      "flux"
      "proximity"
      "python_script"
      "schedule"
      "timer"
      "search"
      "history"
      "history_stats"
      "logger"
      "uptime"
      # Math
      "bayesian"
      "derivative"
      "integration"
      "compensation"
      "filter"
      "min_max"
      "random"
      "simulated"
      "statistics"
      "threshold"
      "trend"
      # Integrations (simulated)
      "input_boolean"
      "input_button"
      "input_datetime"
      "input_number"
      "input_select"
      "input_text"
      "scrape"
      "shell_command"
      "script"
      "intent_script"
      "shopping_list"
      # Integrations (computed)
      "sun"
      "moon"
      "season"
      "workday"
      "person"
      # Integrations (local)
      "zha"
      "cups"
      "octoprint"
      "esphome"
      "tag"
      "vlc"
      "vlc_telnet"
      "jellyfin"
      "caldav"
      "cpuspeed"
      "hddtemp"
      "pi_hole"
      "systemmonitor"
      "iperf3"
      "system_bridge"
      # Integrations (remote)
      "tile"
      "met"
      "radio_browser"
      "google_translate"
      "digital_ocean"
    ];
    config = {
      default_config = {};
    };
  };
  nixpkgs.config.permittedInsecurePackages = [ # TODO: Remove this at some point?
    "openssl-1.1.1w"
  ];
}
