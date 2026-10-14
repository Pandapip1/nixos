# NixOS module for zswap configuration.
#
# zswap is a compressed RAM cache that sits in front of a backing swap device.
# Pages being swapped out are compressed and stored in a RAM pool instead of
# written to disk immediately. When the pool fills, LRU pages are evicted to
# the backing device.
#
# Note: zswap and zram serve overlapping roles. Using both simultaneously is
# generally not recommended. If you want pure in-RAM compressed swap with no
# backing device, use zramSwap instead.
#
# Usage:
#   zswap = {
#     enable = true;
#     compressor = "zstd";
#     zpool = "zsmalloc";
#     maxPoolPercent = 20;
#     shrinkerEnabled = true;
#     acceptThresholdPercent = 90;
#     sameFilledPagesEnabled = true;
#   };

{ config, lib, pkgs, ... }:

let
  cfg = config.zswap;

  # Compressor modules that need to be loaded early (in initrd) so they are
  # available when the zswap.compressor= kernel parameter takes effect.
  # zstd and lzo are built-in on most kernels; others are typically modules.
  compressorModules = {
    lz4    = [ "lz4" "lz4_compress" ];
    lz4hc  = [ "lz4hc" "lz4hc_compress" ];
    zstd   = [ "zstd" ];
    lzo    = [ ];        # built-in on most kernels
    lzo-rle = [ ];
    deflate = [ "deflate" ];
    "842"  = [ "842" ];
  };

  # zpool allocator modules
  zpoolModules = {
    zbud      = [ "zbud" ];
    z3fold    = [ "z3fold" ];
    zsmalloc  = [ "zsmalloc" ];
  };

  extraCompressorModules = compressorModules.${cfg.compressor} or [];
  extraZpoolModules     = zpoolModules.${cfg.zpool} or [];

in {
  options.zswap = {
    enable = lib.mkEnableOption "zswap compressed swap cache" // {
      description = ''
        Whether to enable zswap, a compressed RAM cache for swap pages.

        When enabled, pages being swapped out are compressed and stored in a
        RAM pool rather than written directly to the backing swap device. This
        trades CPU cycles for reduced swap I/O and lower swap latency.

        A swap device must still be configured (via <option>swapDevices</option>)
        for zswap to have a backing store for evicted pages.
      '';
    };

    compressor = lib.mkOption {
      type = lib.types.enum [ "lzo" "lzo-rle" "lz4" "lz4hc" "zstd" "deflate" "842" ];
      default = "zstd";
      description = ''
        Compression algorithm used to compress swap pages.

        <variablelist>
          <varlistentry>
            <term><literal>zstd</literal></term>
            <listitem><para>
              Good compression ratio with reasonable CPU cost. Default on most
              modern kernels. A good general-purpose choice.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>lz4</literal></term>
            <listitem><para>
              Very fast compression and decompression at the cost of a lower
              compression ratio. Preferred when CPU is the bottleneck.
              Requires <option>boot.initrd.systemd.enable</option> to be
              <literal>true</literal> when set at boot time.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>lzo</literal></term>
            <listitem><para>
              Classic algorithm, typically built into the kernel. Slower than
              lz4, somewhat better ratio.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>lzo-rle</literal></term>
            <listitem><para>
              lzo with run-length encoding optimisation, improving performance
              on pages with long runs of identical bytes.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>lz4hc</literal></term>
            <listitem><para>
              High-compression variant of lz4. Slower compression but better
              ratio; decompression speed is the same as lz4.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>deflate</literal></term>
            <listitem><para>zlib deflate. High compression ratio, high CPU cost.</para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>842</literal></term>
            <listitem><para>IBM 842 hardware-accelerated compression (POWER systems).</para></listitem>
          </varlistentry>
        </variablelist>
      '';
    };

    zpool = lib.mkOption {
      type = lib.types.enum [ "zbud" "z3fold" "zsmalloc" ];
      default = "zsmalloc";
      description = ''
        Memory allocator (zpool backend) used to manage the compressed pool.

        <variablelist>
          <varlistentry>
            <term><literal>zsmalloc</literal></term>
            <listitem><para>
              Stores up to two compressed pages per allocation slot. Higher
              memory density than zbud; suitable for most workloads. Default.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>z3fold</literal></term>
            <listitem><para>
              Stores up to three compressed pages per slot. Slightly higher
              density than zsmalloc in some workloads.
            </para></listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>zbud</literal></term>
            <listitem><para>
              Stores at most one compressed page per slot. Lowest density but
              simplest implementation; useful for debugging.
            </para></listitem>
          </varlistentry>
        </variablelist>
      '';
    };

    maxPoolPercent = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 20;
      description = ''
        Maximum percentage of total RAM that the zswap compressed pool may
        occupy. When the pool reaches this limit, the least recently used
        pages are evicted (written) to the backing swap device.

        Lower values reduce the RAM overhead of zswap but increase the
        frequency of writeback to disk. Values between 10 and 30 are
        typical for desktop use.
      '';
    };

    shrinkerEnabled = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to allow the kernel memory shrinker to proactively reclaim
        pages from the zswap pool under memory pressure, writing them to the
        backing swap device before the pool is full.

        When disabled, the pool will only shrink when it reaches
        <option>maxPoolPercent</option>. Enabling this reduces the chance of
        sudden latency spikes when the pool fills, at the cost of more
        frequent writeback under pressure.
      '';
    };

    acceptThresholdPercent = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 90;
      description = ''
        Hysteresis threshold as a percentage of <option>maxPoolPercent</option>.
        After the pool becomes full and pages start being evicted to disk,
        zswap will not accept new pages until the pool has shrunk to this
        percentage of its maximum size.

        This prevents pathological thrashing where pages are rapidly cycled
        in and out of the pool under sustained pressure. Set to 100 to
        disable hysteresis entirely.

        Example: with <option>maxPoolPercent</option> set to 20 and this
        option set to 90, zswap will resume accepting pages once the pool
        drops to 18% of RAM.
      '';
    };

    sameFilledPagesEnabled = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable same-value filled page detection. Pages whose
        entire contents are a single repeated byte value (most commonly zero
        pages) are identified before compression and stored as a single value
        rather than being passed to the compressor. This is essentially free
        in CPU terms and saves pool space for very common page patterns.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Kernel parameters set at boot time. These take effect before any sysfs
    # write is possible and ensure the correct compressor module is active
    # from the first swap operation.
    boot.kernelParams = [
      "zswap.enabled=1"
      "zswap.compressor=${cfg.compressor}"
      "zswap.zpool=${cfg.zpool}"
      "zswap.max_pool_percent=${toString cfg.maxPoolPercent}"
      "zswap.shrinker_enabled=${if cfg.shrinkerEnabled then "1" else "0"}"
      "zswap.accept_threshold_percent=${toString cfg.acceptThresholdPercent}"
      "zswap.same_filled_pages_enabled=${if cfg.sameFilledPagesEnabled then "1" else "0"}"
    ];

    # The compressor and zpool modules must be present in the initrd so they
    # are available when zswap initialises during early boot, before the main
    # module tree is mounted.
    boot.initrd.kernelModules =
      extraCompressorModules ++ extraZpoolModules;

    # Warn when zram and zswap are both active, as they serve overlapping roles.
    warnings = lib.optional
      (config.zramSwap.enable or false)
      "zswap and zramSwap are both enabled. They serve overlapping roles and using both simultaneously may lead to suboptimal memory management. Consider using one or the other.";
  };
}
