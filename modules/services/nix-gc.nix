{
  systemd.services.nix-gc = let
    configurationLimit = 16;
  in lib.mkForce {
    description = "Nix Garbage Collector";
    script = ''
      ${lib.getExe' pkgs.nix "nix-env"} --delete-generations +${toString configurationLimit} --profile /nix/var/nix/profiles/system
      exec ${lib.getExe' pkgs.nix "nix-collect-garbage"}
    '';
    serviceConfig.Type = "oneshot";
    startAt = "daily";
  };
  systemd.timers.nix-gc.timerConfig.Persistent = lib.mkForce true;
}
