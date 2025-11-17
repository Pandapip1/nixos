{
  lib,
  pkgs,
  config,
  ...
}:

{
  options.nix-gc.configurationLimit = lib.mkOption {
    type = lib.types.int;
    default = 16;
    description = "Number of generations to keep when running nix-gc";
  };

  systemd.services.nix-gc = lib.mkForce {
    description = "Nix Garbage Collector";
    script = ''
      ${lib.getExe' pkgs.nix "nix-env"} --delete-generations +${toString config.nix-gc.configurationLimit} --profile /nix/var/nix/profiles/system
      exec ${lib.getExe' pkgs.nix "nix-collect-garbage"}
    '';
    serviceConfig.Type = "oneshot";
    startAt = "daily";
  };

  systemd.timers.nix-gc.timerConfig.Persistent = lib.mkForce true;
}
