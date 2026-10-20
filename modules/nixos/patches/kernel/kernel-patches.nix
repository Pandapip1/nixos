{ config, lib, ... }:

{
  boot.kernelPatches = [
    {
      name = "Rust Support";
      patch = null;
      features.rust = true;
    }
    {
      name = "resolution-quirk-match";
      patch = ./0001-drm-edid-match-on-active-resolution.patch;
    }
    {
      name = "xreal-light-non-desktop";
      patch = ./0002-drm-edid-add-xreal-air-non-desktop-quirk-in-SBS.patch;
    }
  ] ++ lib.optionals config.hardware.asahi.enable [
    {
      # The DT match is restricted to the T600x SMC. The driver also ignores
      # every PMU key which the firmware does not advertise as a readable flt.
      name = "asahi-macsmc-pmu-temperatures";
      patch = ./0003-hwmon-macsmc-pmu-temperature-sensors.patch;
      features = {
        SENSORS_MACSMC_PMU_TEMP = true;
      };
    }
  ];
}
