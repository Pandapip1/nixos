{
  lib,
  config,
  ...
}:

let
  cfg = config.boot;
  attrNamesToTrue = lib.types.coercedTo (lib.types.listOf lib.types.str) (
    enabledList: lib.genAttrs enabledList (_: true)
  ) (lib.types.attrsOf lib.types.bool);
in
{
  options.boot.forbiddenKernelModules = lib.mkOption {
    type = attrNamesToTrue;
    default = { };
    example = [
      "cirrusfb"
      "i2c_piix4"
    ];
    description = ''
      Set of names of kernel modules that should never be loaded,
      even manually. This can either be a list of modules or an
      attrset. In an attrset, names that are set to `true`
      represent modules that will be blacklisted.
    '';
    apply = mods: lib.attrNames (lib.filterAttrs (_: v: v) mods);
  };

  config.boot = {
    blacklistedKernelModules = cfg.forbiddenKernelModules;
    extraModprobeConfig = ''
      # Disallowed loading by boot.forbiddenKernelModules
      ${lib.concatStringsSep "\n" (lib.map (mod: "install ${mod} /bin/false") cfg.forbiddenKernelModules)}
    '';
  };
}
