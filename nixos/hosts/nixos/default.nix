{ lib, ... }:

{
  networking.hostName = lib.mkDefault "nixos";

  imports = [
    ../../configuration.nix
    ../../hardware.nix
    ../../desktop
    ../../desktop/genericUsers.nix

    # You should copy flake.example.nix in your /etc/nixos and apply it with pure mode
    # This is why:
    # - Don't save the hardware-configuration.nix in this repository for abstracted use-case in several devices even after GH-712.
    # - Don't refer /etc/nixos/*.nix  here, it requires impure mode
    # - Impure mode is annoy, when including it, flake check will fail
    # - We can't partially run flake check. See https://github.com/NixOS/nix/issues/8881
  ];

  boot.loader.systemd-boot = {
    enable = true;
    # https://discourse.nixos.org/t/no-space-left-on-boot/24019/20
    configurationLimit = 10;
  };

  # Pseudo values to pass flake check validations
  # You should override in your hardware-configuration.nix

  fileSystems."/" = lib.mkDefault {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.networkmanager = lib.mkDefault {
    unmanaged = [
    ];
  };

}
