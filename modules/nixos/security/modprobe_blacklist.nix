{
  boot = {
    modprobeConfig.useUbuntuModuleBlacklist = true;
    forbiddenKernelModules = {
      tipc = true;
      rds = true;
      sctp = true;
      dccp = true;
    };
  };
}
