{
  lib,
  config,
  ...
}:

{
  # TODO: Remove mkIf once https://github.com/HeitorAugustoLN/cosmic-manager/issues/64 resolved
  home-manager.sharedModules = lib.mkIf config.services.desktopManager.cosmic.enable [
    (
      {
        cosmicLib,
        ...
      }:
      let
        inherit (cosmicLib.cosmic) mkRON;
        mkOptional = mkRON "optional";
        mkEnum = mkRON "enum";
        mkMap = mkRON "map";
        mkTuple = mkRON "tuple";
        mkTuple' =
          let
            mkTuple'Helper = i: arr: if i == 0 then mkTuple arr else it: mkTuple'Helper (i - 1) (arr ++ [ it ]);
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
                  accent = mkOptional primary;
                  destructive = mkOptional danger;
                  neutral_tint = mkOptional gray;
                  success = mkOptional success;
                  warning = mkOptional warning;

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

                  frosted = mkEnum "Medium";
                  frosted_windows = true;
                  frosted_panel = true;
                  frosted_system_interface = true;
                  frosted_applets = true;
                  frosted_maximized_apps = true;
                };
                common_palette_values = {
                  # TODO
                };
              in
              {
                dark = {
                  bg_color = mkOptional (dark // {
                    alpha = 0.95;
                  });
                  primary_container_bg = mkOptional (black // {
                    alpha = 1.;
                  });
                  text_tint = mkOptional light;
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
                  bg_color = mkOptional (light // {
                    alpha = 0.95;
                  });
                  primary_container_bg = mkOptional (white // {
                    alpha = 1.;
                  });
                  text_tint = mkOptional dark;
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
                enumStandard = mkEnum "Standard";
              in
              {
                apply_theme_global = true;
                header_size = enumStandard;
                interface_density = enumStandard;
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
                "com.system76.CosmicTerm"
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
                scroll_config = mkOptional {
                  method = mkOptional null;
                  scroll_button = mkOptional null;
                  scroll_factor = mkOptional 1.0;
                  natural_scroll = mkOptional false;
                };
              }
              // common_input;
              input_touchpad = {
                scroll_config = mkOptional {
                  method = mkOptional null;
                  scroll_button = mkOptional null;
                  scroll_factor = mkOptional 1.6;
                  natural_scroll = mkOptional true;
                };
              }
              // common_input;
            };
          shortcuts = [
            {
              key = "Super+XF86MonBrightnessUp";
              action = mkEnum {
                variant = "System";
                value = [ (mkEnum "KeyboardBrightnessUp") ];
              };
            }
            {
              key = "Super+XF86MonBrightnessDown";
              action = mkEnum {
                variant = "System";
                value = [ (mkEnum "KeyboardBrightnessDown") ];
              };
            }
          ];

          systemActions = mkMap [
            {
              key = mkEnum "KeyboardBrightnessUp";
              value = "brightnessctl -d '*::kbd_backlight' set +10%";
            }
            {
              key = mkEnum "KeyboardBrightnessDown";
              value = "brightnessctl -d '*::kbd_backlight' set 10%-";
            }
          ];
        };
      }
    )
  ];
  nixpkgs.overlays = [
    (final: prev: {
      cosmic-ext-ctl = prev.cosmic-ext-ctl.overrideAttrs (old: rec {
        src = final.fetchFromGitHub {
          owner = "Pandapip1";
          repo = "cosmic-ctl";
          rev = "2210d5f9e5308c0df6f9fb5be66f0ae8241a9bc1"; # update-libcosmic
          hash = "sha256-Z7xuEsw8X2BVp+86fPDyEnAinUotQxWi4yMeHwICYz4=";
        };

        cargoDeps = final.rustPlatform.importCargoLock {
          lockFile = src + "/Cargo.lock";
          allowBuiltinFetchGit = true;
        };
      });
    })
  ];
}
