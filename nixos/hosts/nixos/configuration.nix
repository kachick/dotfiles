{
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.generic.nixosModules.nixos.default
  ];
}
