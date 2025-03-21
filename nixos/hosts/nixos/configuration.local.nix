# Intentionally renamed from configuration.nix, keeping original generated config would be useful for debugging

{
  # config,
  # lib,
  # nixpkgs,
  generic,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    generic.nixosConfigurations.nixos.default
  ];
}
