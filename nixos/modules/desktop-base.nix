{ lib, outputs, ... }:
{
  imports = [
    ../configuration.nix
    outputs.nixosModules.home-manager
    ../desktop
  ];

  # Use Plymouth and quiet boot so systemd stage 1 logs do not collide with
  # LUKS passphrase prompts on the console.
  boot = {
    plymouth.enable = lib.mkDefault true;
    consoleLogLevel = lib.mkDefault 3;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "rd.udev.log_level=3"
      "systemd.show_status=auto"
    ];

    # Default bootloader for desktop systems
    loader.systemd-boot = {
      enable = lib.mkDefault true;
      memtest86.enable = true;
    };
  };

  _module.args.overlays = [ outputs.overlays.default ];
}
