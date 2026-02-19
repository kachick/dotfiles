{ outputs, ... }:
{
  imports = [
    outputs.homeManagerModules.common
    ../desktop.nix
  ];
}
