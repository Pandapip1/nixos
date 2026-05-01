{
  zswap = {
    enable = true;
    compressor = "lz4";
    zpool = "zsmalloc";
    maxPoolPercent = 35;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.vfs_cache_pressure" = 50;
  };
}
