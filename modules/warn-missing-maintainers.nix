{
  lib,
  ...
}:

{
  nixpkgs.overlays = [
    (
      final: prev:
      let
        safeIsDerivation =
          value:
          let
            r = builtins.tryEval (lib.isDerivation value);
          in
          r.success && r.value;

        safeIsAttrs =
          value:
          let
            r = builtins.tryEval (builtins.isAttrs value);
          in
          r.success && r.value;

        wantsRecursion =
          value:
          let
            r = builtins.tryEval (value.recurseForDerivations or false);
          in
          r.success && r.value == true;

        hasNoMaintainers =
          pkg:
          let
            r = builtins.tryEval (pkg.meta.maintainers or pkg.meta.teams or [ ]);
          in
          !r.success || r.value == [ ];

        warn = path: pkg: lib.warnOnInstantiate "package '${path}' has no maintainers" pkg;

        maybeWarn =
          path: value:
          if safeIsDerivation value then
            (if hasNoMaintainers value then warn path value else value)
          else if safeIsAttrs value && wantsRecursion value then
            lib.mapAttrs (name: v: maybeWarn "${path}.${name}" v) value
          else
            value;

        pythonMaybeWarn =
          _pyfinal: pyprev:
          lib.mapAttrs (
            name: value:
            if safeIsDerivation value && hasNoMaintainers value then
              warn "pythonPackages.${name}" value
            else
              value
          ) pyprev;
      in
      (lib.mapAttrs maybeWarn prev)
      // {
        pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [ pythonMaybeWarn ];
      }
    )
  ];
}
