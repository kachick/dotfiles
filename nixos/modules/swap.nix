{ ... }:
{
  # https://wiki.nixos.org/wiki/Swap#Zram_swap
  zramSwap.enable = true;

  # Required for automatic hibernation resume without manual offset/device configuration.
  # See also: https://discourse.nixos.org/t/is-it-possible-to-hibernate-with-swap-file/2852/5
  boot.initrd.systemd.enable = true;

  # Highly recommended when using zram to prevent system lockups.
  # See also: https://wiki.nixos.org/wiki/Swap#Zram_swap
  systemd.oomd.enable = true;
}
