{
  boot.modprobeConfig.useUbuntuModuleBlacklist = true;
  boot.blacklistedKernelModules = [
    "tipc"
    "rds"
    "sctp"
    "dccp"
  ];
}
