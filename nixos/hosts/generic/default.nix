{
  lib,
  inputs,
  ...
}:

{
  # Keep same name with flake outputs
  networking.hostName = lib.mkDefault "generic";

  imports = [
    inputs.home-manager-linux.nixosModules.home-manager
    ../../configuration.nix
    ../../hardware.nix
    ../../desktop
    ../../desktop/genericUsers.nix

    # ./hardware-configuration.nix # UPDATEME: Comment-in only in your new device
  ];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  #
  # TODO: Bump to 25.11 once that nixos-25.11 release is out.
  #       Daily‑use machines should keep their current stateVersion.
  #       This “generic” host is a template, so tracking the latest release makes sense here.
  system.stateVersion = "25.05"; # Did you read the comment?

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

  # Typically requires this config in Japanese vendors laptops
  # console.keyMap = "jp106";
}
