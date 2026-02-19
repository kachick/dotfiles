{ outputs, ... }:
{
  imports = [
    outputs.homeManagerModules.common
    ../kachick.nix
  ];
}
