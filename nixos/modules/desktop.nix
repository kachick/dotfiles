{ lib, outputs, ... }:
{
  imports = [
    ../configuration.nix
    outputs.nixosModules.home-manager
    ../desktop
  ];

  # Default bootloader for desktop systems
  boot.loader.systemd-boot = {
    enable = lib.mkDefault true;
    memtest86.enable = true;
  };

  _module.args.overlays = [ outputs.overlays.default ];
}
