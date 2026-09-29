{ ... }:
{
  # Use zswap instead of zram when a disk swapfile is present (e.g. for hibernation).
  #
  # Why zswap instead of zram?
  # 1. zswap works as a compressed RAM cache in front of the disk swap.
  #    When the memory pool gets full, it moves old pages to the disk swap.
  # 2. zram is a separate swap disk. If we use both zram and a swapfile,
  #    zram fills up first. But it never moves old pages to the disk.
  #    Old, unused pages stay in fast RAM forever, and active data goes to the slow disk (LRU inversion).
  #
  # See also:
  # - https://chrisdown.name/2026/03/24/zswap-vs-zram-when-to-use-what.html
  # - https://blog.matthewbrunelle.com/swap-zram-zswap-and-hibernate-on-nixos/
  boot.zswap.enable = true;

  # Swappiness of 100 treats anonymous memory (app memory) and file cache equally.
  # On fast SSDs with zswap, compressed swap in RAM is cheap.
  # A higher swappiness keeps useful file caches in RAM and moves cold data to zswap.
  #
  # See also:
  # - https://docs.kernel.org/admin-guide/sysctl/vm.html#swappiness
  # - https://chrisdown.name/ja/2018/01/02/in-defence-of-swap.html
  boot.kernel.sysctl."vm.swappiness" = 100;

  # Required for automatic hibernation resume without manual offset/device configuration.
  # See also: https://discourse.nixos.org/t/is-it-possible-to-hibernate-with-swap-file/2852/5
  boot.initrd.systemd.enable = true;

  # Keep systemd-oomd enabled to protect the system under heavy memory pressure.
  systemd.oomd.enable = true;
}
