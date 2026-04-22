{ lib, ... }:
{
  # https://wiki.nixos.org/wiki/Swap#Zram_swap
  zramSwap.enable = true;

  # Required for automatic hibernation resume without manual offset/device configuration.
  # See also: https://discourse.nixos.org/t/is-it-possible-to-hibernate-with-swap-file/2852/5
  boot.initrd.systemd.enable = true;

  # Highly recommended when using zram to prevent system lockups.
  # See also: https://wiki.nixos.org/wiki/Swap#Zram_swap
  systemd.oomd.enable = true;

  # Disable strict shell checks due to a bug in nixos-25.11 oomd-utils.
  # TODO: Re-enable this in NixOS 26.05 once the following fix is available.
  # See also: https://github.com/NixOS/nixpkgs/pull/466869
  systemd.enableStrictShellChecks = lib.mkForce false;
}
