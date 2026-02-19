{ lib, outputs, ... }:
{
  imports = [
    ../configuration.nix
    outputs.nixosModules.home-manager
    ../desktop
  ];

  # Default bootloader for desktop systems
  boot.loader.systemd-boot.enable = lib.mkDefault true;

  nixpkgs.overlays = [ outputs.overlays.default ];

  _module.args.overlays = [ outputs.overlays.default ];
}
