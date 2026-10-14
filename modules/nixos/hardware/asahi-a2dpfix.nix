{
  lib,
  pkgs,
  config,
  ...
}:

lib.mkIf (config.hardware.asahi.enable && config.hardware.bluetooth.enable) {
  systemd.services.bt-a2dp-fix = {
    description = "Bluetooth A2DP stutter fix for Apple Silicon (BCM4377/4378/4387)";
    after = [ "bluetooth.target" ];
    wants = [ "bluetooth.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 5;
      ExecStart = pkgs.writeShellScript "bt-a2dp-fix.sh" ''
        ${lib.getExe' pkgs.expect "unbuffer"} ${lib.getExe' pkgs.bluez "bluetoothctl"} --monitor | while read -r line; do
          if [[ "$line" =~ Device.*([0-9A-F:]{17}).*Connected:\ yes ]]; then
            mac="''${BASH_REMATCH[1]}"
            sleep 2
            ${lib.getExe' pkgs.bluez "bluetoothctl"} info "$mac" | grep -q "Audio Sink" || continue
            handle=$(${lib.getExe' pkgs.bluez "hcitool"} con | grep -i "$mac" | grep -oP 'handle \K[0-9]+')
            [[ -n "$handle" ]] && ${lib.getExe' pkgs.bluez "hcitool"} cmd 0x3f 0x57 "$(printf 0x%02X $handle)" 0x00 0x01
          fi
        done
      '';
    };
  };

  services.pipewire.wireplumber.extraConfig."51-bt-latency" = {
    "monitor.bluez.rules" = [
      {
        matches = [ { "node.name" = "~bluez_output.*"; } ];
        actions.update-props."latency.internal.ns" = 100000000;
      }
    ];
  };
}