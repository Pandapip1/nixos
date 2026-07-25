{
  lib,
  config,
  ...
}:

{
  home-manager.sharedModules = [
    (
      {
        cosmicLib,
        ...
      }:
      let
        inherit (cosmicLib.cosmic) mkRON;
        mkOptional = mkRON "optional";
        mkEnum = mkRON "enum";
        mkTuple = mkRON "tuple";
        mkTuple' =
          let
            mkTuple'Helper =
              i: arr: it:
              if i == 0 then
                mkTuple [ ]
              else if i == 1 then
                mkTuple [ it ]
              else
                mkTuple'Helper (i - 1) (arr ++ [ it ]);
          in
          i: mkTuple'Helper i [ ];
        mkTupleRep = i: val: mkTuple (lib.replicate i val);
        hexToRgb =
          let
            hexDigits = {
              "0" = 0;
              "1" = 1;
              "2" = 2;
              "3" = 3;
              "4" = 4;
              "5" = 5;
              "6" = 6;
              "7" = 7;
              "8" = 8;
              "9" = 9;
              a = 10;
              b = 11;
              c = 12;
              d = 13;
              e = 14;
              f = 15;
              A = 10;
              B = 11;
              C = 12;
              D = 13;
              E = 14;
              F = 15;
            };

            hexPairToInt =
              pair: (hexDigits.${builtins.substring 0 1 pair}) * 16 + hexDigits.${builtins.substring 1 1 pair};

            hexToRgb =
              hex:
              let
                cleaned =
                  if builtins.substring 0 1 hex == "#" then
                    builtins.substring 1 (builtins.stringLength hex - 1) hex
                  else
                    hex;
              in
              {
                red = hexPairToInt (builtins.substring 0 2 cleaned) / 255.0;
                green = hexPairToInt (builtins.substring 2 2 cleaned) / 255.0;
                blue = hexPairToInt (builtins.substring 4 2 cleaned) / 255.0;
              };
          in
          hexToRgb;

        primary = hexToRgb "#da3e8c";
        primary_darker = hexToRgb "#9b319b";
        secondary = hexToRgb "#5f62fc";
        tertiary = hexToRgb "#fabc2a";

        danger = hexToRgb "#C7162E";
        warning = hexToRgb "#E65F20";
        success = hexToRgb "#2BB23D";

        light = hexToRgb "#f2edeb";
        dark = hexToRgb "#262525";
        gray = hexToRgb "#777777";
        black = hexToRgb "#000000";
        white = hexToRgb "#ffffff";
      in
      {
        wayland.desktopManager.cosmic = {
          enable = config.services.desktopManager.cosmic.enable;
          appearance = {
            theme =
              let
                common_theming = {
                  accent = primary;
                  destructive = danger;
                  neutral_tint = gray;
                  success = success;
                  warning = warning;

                  active_hint = 3;
                  gaps = mkTuple' 2 0 8;

                  corner_radii = {
                    radius_0 = mkTupleRep 4 0.0;
                    radius_xs = mkTupleRep 4 4.0;
                    radius_s = mkTupleRep 4 8.0;
                    radius_m = mkTupleRep 4 16.0;
                    radius_l = mkTupleRep 4 32.0;
                    radius_xl = mkTupleRep 4 160.0;
                  };

                  spacing = {
                    space_none = 0;
                    space_xxxs = 4;
                    space_xxs = 8;
                    space_xs = 12;
                    space_s = 16;
                    space_m = 24;
                    space_l = 32;
                    space_xl = 48;
                    space_xxl = 64;
                    space_xxxl = 128;
                  };

                  is_frosted = true;
                };
                common_palette_values = {
                  # TODO
                };
              in
              {
                dark = {
                  bg_color = dark // {
                    alpha = 0.95;
                  };
                  primary_container_bg = black // {
                    alpha = 1.0;
                  };
                  text_tint = light;
                  # secondary_container_bg = TODO
                  # window_hint = TODO
                  # palette = mkOptional {
                  #   value = [
                  #     (
                  #       {
                  #         name = "pandapip1-dark";
                  #       }
                  #       // common_palette_values
                  #     )
                  #   ];
                  #   variant = "Dark";
                  # };
                }
                // common_theming;
                light = {
                  bg_color = light // {
                    alpha = 0.95;
                  };
                  primary_container_bg = white // {
                    alpha = 1.0;
                  };
                  text_tint = dark;
                  # secondary_container_bg = TODO
                  # window_hint = TODO
                  # palette = mkOptional {
                  #   value = [
                  #     (
                  #       {
                  #         name = "pandapip1-light";
                  #       }
                  #       // common_palette_values
                  #     )
                  #   ];
                  #   variant = "Light";
                  # };
                }
                // common_theming;
                mode = "dark";
              };
            toolkit =
              let
                enumNormal = mkEnum "Normal";
              in
              {
                apply_theme_global = true;
                header_size = "Standard";
                interface_density = "Standard";
                icon_theme = "Cosmic";
                interface_font = {
                  family = "Noto Sans";
                  stretch = enumNormal;
                  style = enumNormal;
                  weight = enumNormal;
                };
                monospace_font = {
                  family = "Noto Sans Mono";
                  stretch = enumNormal;
                  style = enumNormal;
                  weight = enumNormal;
                };

                show_maximize = true;
                show_minimize = false;
              };
          };
          applets = {
            app-list.settings = {
              enable_drag_source = false;
              favorites = [
                "com.system76.CosmicFiles"
                "thunderbird"
                "firefox"
                "codium"
                "com.system76.CosmicEdit"
                "kitty"
                "com.system76.CosmicSettings"
              ];
            };
            audio.settings = {
              show_media_controls_in_top_panel = true;
            };
            time.settings = {
              first_day_of_week = 6;
              military_time = true;
              show_date_in_top_panel = true;
              show_seconds = true;
              show_weekday = true;
            };
          };
          compositor =
            let
              common_input = {
                acceleration = mkOptional {
                  profile = mkOptional (mkEnum "Flat");
                  speed = 0.0;
                };
              };
            in
            {
              input_default = {
                scroll_config.natural_scroll = false;
              }
              // common_input;
              input_touchpad = {
                scroll_config.natural_scroll = true;
              }
              // common_input;
            };
        };
      }
    )
  ];
}
