{ outputs, ... }:
{
  imports = [
    outputs.homeManagerModules.dev
    ../desktop.nix
  ];
}
