{ config, lib, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    verbose = true;
    sharedModules = [
      {
        # Enable shell integration
        programs.bash.enable = true;
        programs.zsh.enable = true;
        programs.fish.enable = true;
        programs.nushell.enable = true;
      }
    ];
  } // lib.optionalAttrs (config.moduleClass == "nixos") {
    startAsUserService = true;
  };
}
