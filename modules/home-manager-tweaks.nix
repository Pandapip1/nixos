{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    startAsUserService = true;
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
  };
}
