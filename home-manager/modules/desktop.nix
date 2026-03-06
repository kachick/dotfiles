{ outputs, ... }:
{
  imports = [
    outputs.homeManagerModules.common
    ../programs/desktop.nix
  ];
}
